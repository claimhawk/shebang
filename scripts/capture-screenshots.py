#!/usr/bin/env python3
"""
Shebang! Screenshot Automation
Captures all portal pages for marketing materials.

Usage:
    python3 scripts/capture-screenshots.py [--output DIR] [--width WIDTH] [--height HEIGHT]

Requirements:
    - Web portal must be running on localhost:8080
    - Run: python3 web/server.py (in another terminal)

Copyright (c) 2025 Michael O'Neal
Licensed under the MIT License
"""

import argparse
import sys
import time
from pathlib import Path
from typing import List, Tuple
from urllib.request import urlopen
from urllib.error import URLError

# Project root
PROJECT_ROOT = Path(__file__).parent.parent
DEFAULT_OUTPUT = PROJECT_ROOT / "docs" / "marketing" / "screenshots"

# Page configurations: (path, filename, description)
PAGES: List[Tuple[str, str, str]] = [
    ("/", "dashboard.png", "Main dashboard with kanban board and metrics"),
    ("/features", "features.png", "Features page showing all implemented features"),
    ("/git-history", "git-history.png", "Git history with commit timeline"),
    ("/docs", "docs-index.png", "Documentation index page"),
    ("/docs/ROADMAP.md", "roadmap.png", "Roadmap documentation"),
    ("/docs/FEATURES.md", "features-doc.png", "Features documentation"),
]

# Default viewport size (optimized for marketing screenshots)
DEFAULT_WIDTH = 1920
DEFAULT_HEIGHT = 1080


def check_server_running(base_url: str = "http://localhost:8080") -> bool:
    """Check if the web portal is running."""
    try:
        urlopen(base_url, timeout=2)
        return True
    except (URLError, OSError):
        return False


def capture_screenshots_selenium(
    output_dir: Path,
    base_url: str = "http://localhost:8080",
    width: int = DEFAULT_WIDTH,
    height: int = DEFAULT_HEIGHT,
) -> None:
    """Capture screenshots using Selenium."""
    try:
        from selenium import webdriver
        from selenium.webdriver.chrome.options import Options
        from selenium.webdriver.chrome.service import Service
        from selenium.webdriver.common.by import By
        from selenium.webdriver.support import expected_conditions as EC
        from selenium.webdriver.support.ui import WebDriverWait
    except ImportError:
        print("ERROR: Selenium not installed.")
        print("Install with: pip install selenium")
        sys.exit(1)

    # Setup Chrome options
    chrome_options = Options()
    chrome_options.add_argument("--headless")
    chrome_options.add_argument(f"--window-size={width},{height}")
    chrome_options.add_argument("--disable-gpu")
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")

    # Create driver
    try:
        driver = webdriver.Chrome(options=chrome_options)
    except Exception as e:
        print(f"ERROR: Failed to create Chrome driver: {e}")
        print("\nTroubleshooting:")
        print("1. Install ChromeDriver: brew install chromedriver")
        print("2. Or use Playwright: pip install playwright && playwright install")
        sys.exit(1)

    output_dir.mkdir(parents=True, exist_ok=True)

    print(f"\nCapturing screenshots to: {output_dir}\n")
    print(f"Viewport: {width}x{height}")
    print(f"Pages to capture: {len(PAGES)}\n")

    try:
        for path, filename, description in PAGES:
            url = f"{base_url}{path}"
            output_file = output_dir / filename

            print(f"📸 {description}")
            print(f"   URL: {url}")
            print(f"   File: {filename}")

            # Navigate to page
            driver.get(url)

            # Wait for page to load (wait for body element)
            WebDriverWait(driver, 10).until(
                EC.presence_of_element_located((By.TAG_NAME, "body"))
            )

            # Additional wait for dynamic content
            time.sleep(2)

            # Take screenshot
            driver.save_screenshot(str(output_file))
            print(f"   ✅ Saved\n")

    finally:
        driver.quit()

    print(f"✅ All screenshots captured to: {output_dir}")


def capture_screenshots_playwright(
    output_dir: Path,
    base_url: str = "http://localhost:8080",
    width: int = DEFAULT_WIDTH,
    height: int = DEFAULT_HEIGHT,
) -> None:
    """Capture screenshots using Playwright."""
    try:
        from playwright.sync_api import sync_playwright
    except ImportError:
        print("ERROR: Playwright not installed.")
        print("Install with: pip install playwright && playwright install")
        sys.exit(1)

    output_dir.mkdir(parents=True, exist_ok=True)

    print(f"\nCapturing screenshots to: {output_dir}\n")
    print(f"Viewport: {width}x{height}")
    print(f"Pages to capture: {len(PAGES)}\n")

    with sync_playwright() as p:
        # Launch browser
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(
            viewport={"width": width, "height": height},
            device_scale_factor=2,  # Retina display quality
        )
        page = context.new_page()

        try:
            for path, filename, description in PAGES:
                url = f"{base_url}{path}"
                output_file = output_dir / filename

                print(f"📸 {description}")
                print(f"   URL: {url}")
                print(f"   File: {filename}")

                # Navigate to page
                page.goto(url, wait_until="networkidle")

                # Additional wait for animations/dynamic content
                page.wait_for_timeout(1000)

                # Take full page screenshot
                page.screenshot(path=str(output_file), full_page=True)
                print(f"   ✅ Saved\n")

        finally:
            browser.close()

    print(f"✅ All screenshots captured to: {output_dir}")


def main() -> None:
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Capture screenshots of Shebang! portal pages"
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=DEFAULT_OUTPUT,
        help=f"Output directory (default: {DEFAULT_OUTPUT})",
    )
    parser.add_argument(
        "--width",
        type=int,
        default=DEFAULT_WIDTH,
        help=f"Viewport width (default: {DEFAULT_WIDTH})",
    )
    parser.add_argument(
        "--height",
        type=int,
        default=DEFAULT_HEIGHT,
        help=f"Viewport height (default: {DEFAULT_HEIGHT})",
    )
    parser.add_argument(
        "--engine",
        choices=["playwright", "selenium", "auto"],
        default="auto",
        help="Screenshot engine to use (default: auto)",
    )
    parser.add_argument(
        "--base-url",
        default="http://localhost:8080",
        help="Base URL of the portal (default: http://localhost:8080)",
    )

    args = parser.parse_args()

    # Check if server is running
    print(f"Checking if portal is running at {args.base_url}...")
    if not check_server_running(args.base_url):
        print(f"\n❌ ERROR: Portal not running at {args.base_url}")
        print("\nStart the portal first:")
        print("    python3 web/server.py\n")
        sys.exit(1)

    print("✅ Portal is running\n")

    # Determine which engine to use
    if args.engine == "auto":
        # Try Playwright first, fall back to Selenium
        try:
            import playwright  # noqa: F401
            engine = "playwright"
        except ImportError:
            try:
                import selenium  # noqa: F401
                engine = "selenium"
            except ImportError:
                print("ERROR: Neither Playwright nor Selenium is installed.")
                print("\nInstall one of:")
                print("  Playwright: pip install playwright && playwright install")
                print("  Selenium:   pip install selenium")
                sys.exit(1)
    else:
        engine = args.engine

    print(f"Using {engine.title()} for screenshot capture\n")

    # Capture screenshots
    if engine == "playwright":
        capture_screenshots_playwright(
            args.output, args.base_url, args.width, args.height
        )
    else:
        capture_screenshots_selenium(
            args.output, args.base_url, args.width, args.height
        )


if __name__ == "__main__":
    main()
