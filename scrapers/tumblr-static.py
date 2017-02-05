#!/usr/bin/env python3

from PIL import Image
import bs4
import io
import os
import re
import requests

class Scraper(object):
    """ Main scraper class responsible for scraping Tumblr blogs

    Attributes:
        url: A string cotaining the url to be scraped
        blog_name: The raw blog name, e.g. "blogname" in blogname.tumblr.com or
            in blogname.com in the case of custom domains.
        output_directory: A string containing the path to the directory where
            images will be saved.
    """

    def __init__(self, url, output_directory = False, parent_directory = "."):
        """ Initialize Scraper class

        Args:
            url: The raw url to be scraped. This can either be of the format
                blogname.tumblr.com, or, if a custom domain is being used,
                blogname.com.
            output_directory: A string containing the name of the directory that
                the images will be saved to. If this is False, as in the default
                case, the output directory name will be parsed out from the URL.
            parent_directory: A string containing the path to the root directory
                that output_directory will be a subdirectory of. The default is
                the current directory.
        """

        if (url.find("http") != 0):
            url = "https://%s" % url
        self.url = "/".join(url.split("/")[0:3])

        blog_name = url.split("/")[2]
        if (url.find("tumblr.com") != -1):
            blog_name = blog_name.split(".")[0]
        else:
            if (blog_name.find("www") == 0):
                blog_name = blog_name.split(".")[1]
            else:
                blog_name = blog_name.split(".")[0]
        self.blog_name = blog_name

        if (output_directory):
            self.output_directory = "%s/%s" % (parent_directory,
                                               output_directory)
        else:
            self.output_directory = "%s/%s" % (parent_directory, blog_name)
        if (not os.path.isdir(self.output_directory)):
            os.makedirs(self.output_directory)
        print("Saving to %s" % self.output_directory)

    def download_image(self, url):
        """ Download an image and save it in self.output_directory

        Does not download the image if the image already exists in
        self.output_directory.

        Args:
            url: A string containing the url of the image to be downloaded
        Returns:
            True if the download succeeded.
            False if the download failed.
        """

        output_path = "%s/%s" % (self.output_directory, url.split("/")[-1])
        if (os.path.isfile(output_path)):
            print("Skipping %s" % url)
        else:
            image = requests.get(url)
            print("%s %d" % (url, image.status_code))

            if (image.status_code == 200):
                image = Image.open(io.BytesIO(image.content))
                image.save(output_path)
                print("%s => %s" % (url, output_path))
                return True
            else:
                return False

    def get_page(self, num):
        """ Parse a page and return info about the page's images and next page

        Args:
            num: An integer representing the page number of the page to be
                downloaded and parsed.
        Returns:
            A dictionary with the following indices:
                next_page: An integer representing the page number of the next
                    page, or False if it does not exist.
                images: An array containing a string of urls to images.
        """

        results = {"images": [], "next_page": False}
        page_url = "%s/page/%d" % (self.url, num)

        page = requests.get(page_url)
        if (page.status_code == 200):
            soup = bs4.BeautifulSoup(page.content, "lxml")

            # Each image has an src tag of the pattern [0-9]+.media.tumblr.com
            results["images"] = list(map(
                lambda x: x["src"],
                soup.find_all(src = re.compile("[0-9]+.media.tumblr.com"))
            ))

            # Each next page/previous page element has an src containing the
            # pattern /page/[0-9]. We need the one with the largest number.
            results["next_page"] = sorted(list(map(
                lambda x: int(x["href"].split("/")[-1]),
                soup.find_all(href = re.compile("/page/[0-9]"))
            )))[-1]

            # If the next page is the current page or previous page, then no
            # next page exists.
            if (results["next_page"] <= num):
                results["next_page"] = False

        return results

    def scrape(self, num = 1):
        """ Recursive function that will scrape an entire blog

        Args:
            num: An integer representing the page to start scraping from.
        """
        print("Scraping page %d" % num)
        results = self.get_page(num)
        for image in results["images"]:
            self.download_image(image)
        if (results["next_page"]):
            self.scrape(results["next_page"])

if (__name__ == "__main__"):
    import optparse

    parser = optparse.OptionParser()
    parser.add_option("-u", "--url", dest = "url", metavar = "URL",
                      help = "The URL to scrape", default = "null")
    parser.add_option("-o", "--output", dest = "output", metavar = "PATH",
                      help = "The subdirectory to save results to (default is "
                             + "the url of the blog)",
                      default = False)
    parser.add_option("-p", "--parent", dest = "parent", metavar = "PATH",
                      help = "The parent directory to save results to (default "
                             + "is the current directory",
                      default = ".")
    (options, args) = parser.parse_args()

    if (options.url != "null"):
        scraper = Scraper(options.url, output_directory = options.output,
                          parent_directory = options.parent)
        scraper.scrape()
    else:
        print("Please provide a URL with --url. See --help for more info.")
