import base64
from argparse import ArgumentParser
from os.path import dirname, join, realpath, getsize
from tbselenium.tbdriver import TorBrowserDriver
from tbselenium.utils import start_xvfb, stop_xvfb
from selenium.webdriver.common.by import By
import regex as re

workdir = dirname(realpath(__file__))

def visit_and_screenshot(driver, url, out_img):
    """Take screenshot of the page."""
    driver.load_url(url, wait_for_page_body=True)
    driver.get_screenshot_as_file(out_img)
    print("Screenshot is saved as %s (%s bytes)" % (out_img, getsize(out_img)))

def main():
    global workdir
    desc = "Take a screenshot using TorBrowserDriver"
    default_url = "https://check.torproject.org"
    parser = ArgumentParser(description=desc)
    parser.add_argument('tbb_path')
    parser.add_argument('output_dir', default=workdir)
    parser.add_argument('url', nargs='?', default=default_url)
    args = parser.parse_args()
    out_img = realpath( join(args.output_dir, "screenshot.png") )

    if default_url is None:
        print("ERROR: cannot detect main URL")
        return 1

    xvfb_display = start_xvfb()

    with TorBrowserDriver(args.tbb_path, headless=True) as driver:
        visit_and_screenshot(driver, default_url, out_img)

    stop_xvfb(xvfb_display)

if __name__ == '__main__':
    main()
