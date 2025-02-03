import csv
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
import datetime

#wget https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/2.5_month.csv

# Load CSV file
file_path = "2.5_month.csv" 
 

def parse_csv(file_path, country):
    earthquakes = []
    with open(file_path, newline='') as csvfile:
        reader = csv.DictReader(csvfile)
        for row in reader:
            if country in row["place"]:
                time = datetime.datetime.fromisoformat(row["time"].replace("Z", ""))
                mag = float(row["mag"])
                date = time.date()
                earthquakes.append((time, mag, date))
    return earthquakes

# Filter by country (e.g., Greece)
country = "Greece"
earthquakes = parse_csv(file_path, country)

print("Earthquakes:",earthquakes)

# Plot all earthquakes in the selected country
plt.figure(figsize=(10, 5))
times, magnitudes, _ = zip(*earthquakes)
plt.scatter(times, magnitudes, color='b', label=f'Earthquakes in {country}')
plt.xlabel("Time")
plt.ylabel("Magnitude")
plt.title(f"Earthquakes in {country}")
plt.legend()
plt.xticks(rotation=45)
plt.grid()
plt.gca().xaxis.set_major_locator(mdates.DayLocator(interval=1))
plt.gca().xaxis.set_major_formatter(mdates.DateFormatter('%Y-%m-%d'))
plt.savefig("earthquakes_scatter.png")
plt.close()

# Compute max magnitude per day
max_per_day = {}
for _, mag, date in earthquakes:
    if date not in max_per_day or mag > max_per_day[date]:
        max_per_day[date] = mag

dates, max_magnitudes = zip(*sorted(max_per_day.items()))

# Plot max earthquake per day
plt.figure(figsize=(10, 5))
plt.scatter(dates, max_magnitudes, color='r', label=f'Max Magnitude per Day in {country}')
plt.xlabel("Date")
plt.ylabel("Max Magnitude")
plt.title(f"Max Earthquake Magnitude per Day in {country}")
plt.legend()
plt.xticks(rotation=45)
plt.grid()
plt.gca().xaxis.set_major_locator(mdates.DayLocator(interval=1))
plt.gca().xaxis.set_major_formatter(mdates.DateFormatter('%Y-%m-%d'))
plt.savefig("max_earthquakes_per_day.png")
plt.close()

print("Plots saved: earthquakes_scatter.png, max_earthquakes_per_day.png")

