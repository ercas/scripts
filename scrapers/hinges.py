#!/usr/bin/env python3

import bs4
import re
import requests

r = requests.get("https://hingescomic.blogspot.com/p/archives.html")
soup = bs4.BeautifulSoup(r.content, "lxml").find("div", {"id": "post-body-766359031254994347"})
n = 1
for a in soup.find_all("a"):
    href = a["href"]
    if (not "blogger" in href):
        r = requests.get(href)
        page_soup = bs4.BeautifulSoup(r.content, "lxml")
        img_url = page_soup.find("div", {"class": "post-body"}).find("img")["src"]
        print("%03d.jpg %s" % (n, img_url))
        with open("%03d.jpg" % n, "wb") as f:
            f.write(requests.get(img_url).content)
        n += 1
