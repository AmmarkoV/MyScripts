// Fits DVD track geometry from a photo of a burned target_slim calibration disc,
// using DiscImageStudio.Core's own rectifier and cross fitter (the Windows app's
// calibration steps 1 and 2, without the UI).
//
// Input: an SVG exported from GIMP (Paths dialog -> Export Path, "all paths")
// containing three paths named "outer" (physical disc edge), "hole" (centre hole
// edge) and "trace" (one bent crosshair arm, clicked from the inside out).
//
// Usage: dotnet run -- paths.svg [--sectors N] [--inner MM] [--outer MM] [--mirror]
//
// Sweep mode (--sweep calib/sweep.sweep.json): the photo is of the radius-sweep
// disc from sweep.py. Every path other than "outer" and "hole" is one traced
// wedge edge lying inside a single band, in any order and with any name.
using System.Globalization;
using System.Text.Json;
using System.Text.RegularExpressions;
using System.Xml.Linq;
using DiscImageStudio.Core.Calibration;

var inv = CultureInfo.InvariantCulture;
if (args.Length < 1) { Console.Error.WriteLine("usage: fit-tool paths.svg [--sectors N] [--inner MM] [--outer MM] [--mirror] [--sweep layout.json]"); return 2; }
string svgPath = args[0];
long sectors = 2_295_104;
double inner = 24, outer = 58;
bool mirror = false;
string? sweepPath = null;
for (int i = 1; i < args.Length; i++)
{
    switch (args[i])
    {
        case "--sectors": sectors = long.Parse(args[++i], inv); break;
        case "--inner": inner = double.Parse(args[++i], inv); break;
        case "--outer": outer = double.Parse(args[++i], inv); break;
        case "--mirror": mirror = true; break;
        case "--sweep": sweepPath = args[++i]; break;
        default: Console.Error.WriteLine($"unknown option {args[i]}"); return 2;
    }
}

Dictionary<string, List<CalibrationPoint>> paths = ReadSvgPaths(svgPath);
foreach (string name in sweepPath is null ? new[] { "outer", "hole", "trace" } : new[] { "outer", "hole" })
    if (!paths.ContainsKey(name))
    {
        Console.Error.WriteLine($"SVG has no path named '{name}'. Found: {string.Join(", ", paths.Keys)}");
        return 1;
    }
Console.WriteLine($"points: {string.Join(" ", paths.Select(p => $"{p.Key}={p.Value.Count}"))}");

// Step 1: rectify the photo from the physical 120 mm edge and 15 mm hole.
CalibrationPhotoFitResult photo = CalibrationPhotoRectifier.Fit(paths["outer"], paths["hole"], 60, 7.5);
if (!photo.Succeeded || photo.Transform is null) { Console.Error.WriteLine($"rectification failed: {photo.Message}"); return 1; }
Console.WriteLine($"rectification: outer rms {photo.OuterRmsPixels:0.0} px, hole rms {photo.HoleRmsPixels:0.0} px");

if (sweepPath is not null)
{
    var edges = paths.Where(p => p.Key is not ("outer" or "hole"))
        .Select(p => (Name: p.Key, Points: p.Value.Select(photo.Transform.SourceToDisc).ToArray())).ToList();
    return Sweep.Fit(sweepPath, edges);
}

CalibrationPoint[] trace = paths["trace"].Select(photo.Transform.SourceToDisc)
    .Select(p => mirror ? new CalibrationPoint(-p.X, p.Y) : p).ToArray();
double rMin = trace.Min(p => Math.Sqrt(p.X * p.X + p.Y * p.Y)), rMax = trace.Max(p => Math.Sqrt(p.X * p.X + p.Y * p.Y));
Console.WriteLine($"trace spans radius {rMin:0.00}-{rMax:0.00} mm{(mirror ? " (mirrored)" : "")}");

// Step 2: fit, widening the radius search box like the app's automatic range.
var parameters = new CalibrationParameters(CalibrationDiscKind.Dvd, inner, outer, sectors, 133.3);
CalibrationTarget target = CalibrationTarget.Create(parameters);
var traces = new[] { new CalibrationCrossTrace(0, trace) };
var options = new CalibrationFitOptions(FitDvdPitch: true, AdaptiveRobustScale: true, AutoRange: true);
CalibrationFitResult? result = null;
double usedRange = 0;
foreach (double range in new[] { 0.02, 0.1, 0.5, 2, 5 })
{
    result = CalibrationCrossFitter.Fit(target, traces, options with { RadiusRangeMm = range });
    usedRange = range;
    if (!result.Succeeded || !result.BoundaryLimited) break;
}

Console.WriteLine($"search range: +/-{usedRange} mm");
foreach (string warning in result!.Warnings) Console.WriteLine($"warning: {warning}");
if (!result.Succeeded || result.BestParameters is null) { Console.Error.WriteLine("fit failed"); return 1; }
for (int i = 0; i < result.Candidates.Count; i++)
{
    CalibrationFitCandidate c = result.Candidates[i];
    Console.WriteLine(string.Format(inv,
        "candidate {0}: inner={1:R} outer={2:R} pitch=({3:R}, {4:R}, {5:R}) rms={6:0.###} mm max={7:0.###} mm outliers={8}",
        i + 1, c.Parameters.InnerRadiusMm, c.Parameters.OuterRadiusMm, c.Parameters.PitchLinear,
        c.Parameters.PitchQuadratic, c.Parameters.PitchCubic, c.RmsErrorMm, c.MaxErrorMm, c.OutlierCount));
}
CalibrationParameters best = result.BestParameters;
bool acceptable = result.RmsErrorMm <= 0.35 && result.Candidates[0].MaxErrorMm <= 0.8;
Console.WriteLine(acceptable
    ? "result: acceptable (app limits: rms <= 0.35 mm, max <= 0.8 mm)"
    : "result: NOT acceptable by the app's limits (rms <= 0.35 mm, max <= 0.8 mm); add or fix trace points");
Console.WriteLine(string.Format(inv,
    "dvd_image.py options: --total-sectors {0} --inner-radius-mm {1:R} --outer-radius-mm {2:R} --pitch-linear {3:R} --pitch-quadratic {4:R} --pitch-cubic {5:R}",
    best.Sectors, best.InnerRadiusMm, best.OuterRadiusMm, best.PitchLinear, best.PitchQuadratic, best.PitchCubic));
return acceptable ? 0 : 3;

// GIMP exports each path as <path id="name" d="M x,y C x,y x,y x,y ...">;
// the anchors are the M point and the last point of every C triple.
static Dictionary<string, List<CalibrationPoint>> ReadSvgPaths(string file)
{
    var result = new Dictionary<string, List<CalibrationPoint>>(StringComparer.OrdinalIgnoreCase);
    foreach (XElement path in XDocument.Load(file).Descendants().Where(e => e.Name.LocalName == "path"))
    {
        string id = (string?)path.Attribute("id") ?? $"path{result.Count}";
        string d = (string?)path.Attribute("d") ?? "";
        var points = new List<CalibrationPoint>();
        foreach (Match command in Regex.Matches(d, @"([MCLZmclz])([^MCLZmclz]*)"))
        {
            double[] n = Regex.Matches(command.Groups[2].Value, @"-?\d+(?:\.\d+)?(?:[eE][-+]?\d+)?")
                .Select(m => double.Parse(m.Value, CultureInfo.InvariantCulture)).ToArray();
            switch (command.Groups[1].Value)
            {
                case "M": case "L":
                    for (int i = 0; i + 1 < n.Length; i += 2) points.Add(new(n[i], n[i + 1]));
                    break;
                case "C":
                    for (int i = 0; i + 5 < n.Length; i += 6) points.Add(new(n[i + 4], n[i + 5]));
                    break;
                case "Z": case "z": break;
                default: throw new InvalidDataException($"path '{id}': relative SVG commands are not supported");
            }
        }
        // A closed GIMP path repeats its first anchor at the end.
        if (points.Count > 1 && points[0] == points[^1]) points.RemoveAt(points.Count - 1);
        result[id] = points;
    }
    return result;
}
