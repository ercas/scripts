#!/usr/bin/python3
import argparse, random, textwrap
from datetime import datetime
from urllib import request
from xml.etree import ElementTree

labels = {
    "clouds": "%",
    "humidity": "%",
    "precipitation": "%",
    "temp": "°F",
    "wind-direction": "°",
    "wind-speed": " mph",
}

parser = argparse.ArgumentParser(description = "display weather using data from weather.gov")
parser.add_argument("latitude",
        help = "latitude of location",
        type = float)
parser.add_argument("longitude",
        help = "longitude of location",
        type = float)
args = parser.parse_args()

def print_weather(latitude, longitude):

    # weather.gov provides two xml files: digitalDWML and dwml.
    # digitalDWML includes detailed, 24-hour forecast data for the next 7 days.
    # dwml includes simple data for the current day as well as text and icons.
    # in this script, digitalDWML is referred to as "detailed" and dwml is
    # referred to as "simple".
    weather_detailed_xml = request.urlopen("http://forecast.weather.gov/MapClick.php?lat="
            + str(latitude) + "&lon=" + str(longitude)
            + "&FcstType=digitalDWML").read()
    weather_simple_xml = request.urlopen("http://forecast.weather.gov/MapClick.php?lat="
            + str(latitude) + "&lon=" + str(longitude)
            + "&FcstType=dwml").read()

    # these variables and functions refer to digitalDWML
    root = ElementTree.fromstring(weather_detailed_xml)
    parameters = root.find("data").find("parameters")
    def temperature(type):
        for node in parameters.iter("temperature"):
            if node.get("type") == type:
                return node

    wrapped_description = " ".join(
            textwrap.wrap(
                ElementTree.fromstring(weather_simple_xml).\
                    find("data").find("parameters").find("weather").\
                    find("weather-conditions").attrib["weather-summary"]
                ,width = 30,break_long_words=False))

    print(
        "Current Weather for "
            + root.find("data").find("location").find("city").text
            + ":\n"
            + wrapped_description
            + "\n\n"
        "Updated: "
            # %z is defective so the timezone is cropped from the date string
            + datetime.strptime(
                root.find("data").find("time-layout").find("start-valid-time").text[:-6],
                "%Y-%m-%dT%H:%M:%S").strftime("%d %B %Y @ %H:%M %p")
            + "\n"
        "Temperature:       "
            + temperature("hourly")[0].text
            + labels["temp"]
            + "\n"
        "Cloud Cover:       "
            + parameters.find("cloud-amount")[0].text
            + labels["clouds"]
            + "\n"
        "Sustained Wind:    "
            + parameters.find("wind-speed")[0].text
            + labels["wind-speed"]
            + " @ "
            + parameters.find("direction")[0].text
            + labels["wind-direction"]
            + "\n"
        "Humidity:          "
            + parameters.find("humidity")[0].text
            + labels["humidity"]
            + "\n"
        "Precipitation:     "
            + parameters.find("probability-of-precipitation")[0].text
            + labels["precipitation"]
    )

try:
    print_weather(args.latitude, args.longitude)
except Exception as error:
    if type(error) == ElementTree.ParseError:
        print("error: invalid coordinates given or weather.gov's xml format has changed.")
    else:
        print("error: " + error)
