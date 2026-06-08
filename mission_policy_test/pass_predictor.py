import os
from datetime import datetime, timedelta
from skyfield.api import Loader, wgs84, Topos

class MissionPolicySimulator:
    def __init__(self, norad_catalog_number, observer_lat, observer_lon, min_altitude_degrees=-90.0):
        # Create skyfield loader, saving data to local folder
        self.load = Loader('./TLE_and_data')
        self.norad_catalog_number = norad_catalog_number
        self.tle_filename = f'tle-CATNR-{self.norad_catalog_number}.txt'
        
        # Load ephemeris data
        self.eph = self.load('de421.bsp')
        
        # Create an observer (Ground Station)
        self.observer = Topos(latitude_degrees=observer_lat, longitude_degrees=observer_lon)
        self.min_altitude_degrees = min_altitude_degrees
        
        # Download or load TLE
        self.satellite = self.__download_satellite_tle()

    def __download_satellite_tle(self):
        norad_url = f'https://celestrak.org/NORAD/elements/gp.php?CATNR={self.norad_catalog_number}&FORMAT=tle'
        # skyfield loader automatically handles caching and reloading if older than a day
        satellite_list = self.load.tle_file(norad_url, filename=self.tle_filename)
        return satellite_list[0]

    def get_next_pass(self):
        """
        Calculates the start and end time of the next orbital pass over the observer.
        Returns a tuple of (start_time, end_time) as datetime objects, or None if no pass found soon.
        """
        ts = self.load.timescale()
        t0 = ts.now()
        # Look ahead 24 hours
        t1 = ts.utc(t0.utc_datetime() + timedelta(hours=24))
        
        # Find passes above the minimum altitude
        t, events = self.satellite.find_events(self.observer, t0, t1, altitude_degrees=self.min_altitude_degrees)
        
        pass_start = None
        pass_end = None
        
        for ti, event in zip(t, events):
            if event == 0: # 0 means satellite rose above altitude
                pass_start = ti.utc_datetime()
            elif event == 2 and pass_start: # 2 means satellite set below altitude
                pass_end = ti.utc_datetime()
                break # We just want the next immediate pass
                
        return pass_start, pass_end

    def is_currently_passing(self):
        """
        Checks if the satellite is currently passing over the observer.
        """
        ts = self.load.timescale()
        now = ts.now()
        
        difference = self.satellite - self.observer
        topocentric = difference.at(now)
        altitude, _, _ = topocentric.altaz()
        
        return altitude.degrees >= self.min_altitude_degrees

if __name__ == "__main__":
    # Example usage based on ISS (NORAD 25544) and a hypothetical ground station in Santiago, Chile (-33.4, -70.6)
    print("--- Mission Policy: Orbital Pass Predictor ---")
    sim = MissionPolicySimulator(norad_catalog_number=25544, observer_lat=-33.4, observer_lon=-70.6)
    
    start, end = sim.get_next_pass()
    if start and end:
        print(f"Next Authorized Window: {start.strftime('%Y-%m-%d %H:%M:%S UTC')} to {end.strftime('%Y-%m-%d %H:%M:%S UTC')}")
    
    if sim.is_currently_passing():
        print("Status: Satellite is CURRENTLY OVERHEAD. Commands ALLOWED.")
    else:
        print("Status: Satellite is OUT OF RANGE. Commands BLOCKED.")
