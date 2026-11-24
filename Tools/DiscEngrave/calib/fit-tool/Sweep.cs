using System.Globalization;
using System.Text.Json;
using DiscImageStudio.Core.Calibration;

/// <summary>
/// Fits the real constant-pitch track radii (inner, outer) to wedge edges traced on
/// the radius-sweep disc. Each band was generated with radii (inner+d, outer+d); at
/// the physical radius r of a sector, the drawn edge appears at photo angle
/// sigma * (thetaReal(r) - thetaGenerated(same sector)) + per-edge offset.
/// </summary>
static class Sweep
{
    private const int ChannelBitsPerSector = 38_688;

    private sealed record Band(int Index, double InnerRadiusMm, double OuterRadiusMm, double ShiftMm);
    private sealed record Edge(string Name, Band Band, double[] Radius, double[] Angle);

    public static int Fit(string layoutPath, List<(string Name, CalibrationPoint[] Points)> traces)
    {
        var inv = CultureInfo.InvariantCulture;
        using JsonDocument layout = JsonDocument.Parse(File.ReadAllText(layoutPath));
        JsonElement root = layout.RootElement;
        long sectors = root.GetProperty("totalSectors").GetInt64();
        double nominalInner = root.GetProperty("innerRadiusMm").GetDouble();
        double nominalOuter = root.GetProperty("outerRadiusMm").GetDouble();
        double length = sectors * (double)ChannelBitsPerSector * root.GetProperty("channelBitNm").GetDouble() * 1e-6;
        Band[] bands = root.GetProperty("bands").EnumerateArray().Select(b => new Band(
            b.GetProperty("index").GetInt32(), b.GetProperty("innerRadiusMm").GetDouble(),
            b.GetProperty("outerRadiusMm").GetDouble(), b.GetProperty("shiftMm").GetDouble())).ToArray();

        var edges = new List<Edge>();
        foreach ((string name, CalibrationPoint[] points) in traces)
        {
            double[] radius = points.Select(p => Math.Sqrt(p.X * p.X + p.Y * p.Y)).ToArray();
            double[] angle = points.Select(p => Math.Atan2(p.Y, p.X)).ToArray();
            double median = radius.Order().ElementAt(radius.Length / 2);
            Band? band = bands.FirstOrDefault(b => median >= b.InnerRadiusMm - 0.12 && median <= b.OuterRadiusMm + 0.12);
            if (points.Length < 3 || band is null)
            {
                Console.WriteLine($"skipping path '{name}': {(points.Length < 3 ? "fewer than 3 points" : $"median radius {median:0.00} mm is not inside a band")}");
                continue;
            }
            edges.Add(new(name, band, radius, angle));
            Console.WriteLine($"edge '{name}': band {band.Index} (shift {band.ShiftMm:+0.00;-0.00} mm), "
                + $"{points.Length} points, radius {radius.Min():0.00}-{radius.Max():0.00} mm");
        }
        if (edges.Select(e => e.Band.Index).Distinct().Count() < 2)
        {
            Console.Error.WriteLine("need edges from at least two different bands");
            return 1;
        }

        // Angle of the real track at radius r, and of the generated track at the same sector.
        double Rms(double inner, double outer, int sigma, out double maxMm)
        {
            double squaredRange = outer * outer - inner * inner, b = squaredRange / (2 * length);
            double sum = 0; int count = 0; maxMm = 0;
            foreach (Edge edge in edges)
            {
                double gi = nominalInner + edge.Band.ShiftMm, go = nominalOuter + edge.Band.ShiftMm;
                double gRange = go * go - gi * gi, gb = gRange / (2 * length);
                var predicted = new double[edge.Radius.Length];
                double c = 0, s = 0;
                for (int i = 0; i < edge.Radius.Length; i++)
                {
                    double r = edge.Radius[i];
                    double progress = (r * r - inner * inner) / squaredRange;
                    double rg = Math.Sqrt(gi * gi + progress * gRange);
                    predicted[i] = sigma * ((r - inner) / b - (rg - gi) / gb);
                    double d = edge.Angle[i] - predicted[i];
                    c += Math.Cos(d); s += Math.Sin(d);
                }
                double offset = Math.Atan2(s, c);
                for (int i = 0; i < edge.Radius.Length; i++)
                {
                    double d = edge.Angle[i] - predicted[i] - offset;
                    double mm = Math.Atan2(Math.Sin(d), Math.Cos(d)) * edge.Radius[i];
                    sum += mm * mm; count++; maxMm = Math.Max(maxMm, Math.Abs(mm));
                }
            }
            return Math.Sqrt(sum / count);
        }

        // Coarse grid (the basin is about +/-0.02 mm wide), then a shrinking local search.
        (double Inner, double Outer, int Sigma, double Rms) best = (0, 0, 0, double.PositiveInfinity);
        foreach (int sigma in new[] { 1, -1 })
            for (double inner = nominalInner - 0.4; inner <= nominalInner + 0.4; inner += 0.004)
                for (double outer = nominalOuter - 0.5; outer <= nominalOuter + 0.5; outer += 0.004)
                {
                    double rms = Rms(inner, outer, sigma, out _);
                    if (rms < best.Rms) best = (inner, outer, sigma, rms);
                }
        for (double step = 0.002; step > 1e-7; step /= 2)
            for (bool improved = true; improved;)
            {
                improved = false;
                foreach ((double di, double dou) in new[] { (step, 0.0), (-step, 0.0), (0.0, step), (0.0, -step), (step, step), (-step, -step) })
                {
                    double rms = Rms(best.Inner + di, best.Outer + dou, best.Sigma, out _);
                    if (rms < best.Rms) { best = (best.Inner + di, best.Outer + dou, best.Sigma, rms); improved = true; }
                }
            }
        Rms(best.Inner, best.Outer, best.Sigma, out double max);
        int otherSigma = -best.Sigma;
        double otherBest = double.PositiveInfinity;
        for (double inner = best.Inner - 0.4; inner <= best.Inner + 0.4; inner += 0.004)
            for (double outer = best.Outer - 0.5; outer <= best.Outer + 0.5; outer += 0.004)
                otherBest = Math.Min(otherBest, Rms(inner, outer, otherSigma, out _));

        Console.WriteLine(string.Format(inv, "fit: inner={0:R} outer={1:R} (constant pitch), direction {2}, rms={3:0.###} mm, max={4:0.###} mm",
            best.Inner, best.Outer, best.Sigma > 0 ? "as photographed" : "mirrored", best.Rms, max));
        Console.WriteLine($"other direction best rms: {otherBest:0.###} mm");
        double gap = otherBest / Math.Max(best.Rms, 1e-9);
        bool acceptable = best.Rms <= 0.2 && max <= 0.6 && gap >= 2;
        Console.WriteLine(acceptable ? "result: acceptable" : "result: NOT reliable (rms <= 0.2, max <= 0.6 and a clearly worse other direction are needed)");
        Console.WriteLine(string.Format(inv, "crosshair disc: ./run.sh calib/target_slim.png --tone-dither 0 --total-sectors {0} --inner-radius-mm {1:R} --outer-radius-mm {2:R} -o calib/crosshair.iso",
            sectors, best.Inner, best.Outer));
        return acceptable ? 0 : 3;
    }
}
