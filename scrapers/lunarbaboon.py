#!/usr/bin/env python3

import bs4
import dateutil.parser
import os
import requests
import time

ROOT = "http://www.lunarbaboon.com/"
PAGE_URL_BASE = "http://www.lunarbaboon.com/comics/?currentPage="

OUTPUT_DIR = "lunarbaboon"

MAX_ATTEMPTS = 5

PAGE_SLEEP = 1
TOO_MANY_REQUESTS_SLEEP = 5
IMAGE_SLEEP = 0.5

def scrape_page(page_number, attempt = 1):
    print("processing page %d (attempt %d)" % (page_number, attempt))

    response = requests.get("%s%d" % (PAGE_URL_BASE, page_number))
    soup = bs4.BeautifulSoup(response.content, "lxml")

    posts = soup.findAll("div", {"class": "journal-entry-wrapper"})

    if (len(posts) > 0):
        for post in posts:
            title = post.find("h2", {"class": "title"}).text.strip().replace("?", "_").replace("/", "_")
            date_string = dateutil.parser.parse(
                post.find("span", {"class": "posted-on"}).text.strip()
            ).strftime("%Y-%m-%d")[:10]
            image_url = (
                "%s/%s" % (
                    ROOT.rstrip("/"),
                    post.find("div", {"class": "body"}).find("img")["src"].lstrip("/")
                )
            ).split("?")[0]
            file_ext = image_url.split(".")[-1]

            output_path = "%s/%s - %s.%s" % (OUTPUT_DIR, date_string, title, file_ext)

            if (os.path.isfile(output_path)):
                print("> %s exists" % output_path)
            else:
                image_response = requests.get(image_url)
                with open(output_path, "wb") as f:
                    f.write(image_response.content)
                print("> %s -> %s" % (image_url, output_path))
                time.sleep(IMAGE_SLEEP)

        time.sleep(PAGE_SLEEP)
    elif (attempt < MAX_ATTEMPTS):
        if (response.status_code == 429):
            print("> error 429 too many requests")
            time.sleep(TOO_MANY_REQUESTS_SLEEP)
        else:
            print("> error %d" % response.status_code)
            time.sleep(PAGE_SLEEP)
        scrape_page(page_number, attempt + 1)

if (__name__ == "__main__"):
    if (not os.path.isdir(OUTPUT_DIR)):
        os.mkdir(OUTPUT_DIR)
    for i in range(32, 146):
        scrape_page(i)
