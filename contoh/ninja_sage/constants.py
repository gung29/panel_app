"""Static configuration shared by the AMF tooling."""

DEFAULT_BASE_URL = "https://play.ninjasage.id"
DEFAULT_ENDPOINT_PATH = "/amf"
DEFAULT_REFERER = "app:/NinjaSage.swf"
DEFAULT_UA = (
    "Mozilla/5.0 (Windows; U; en) AppleWebKit/533.19.4 (KHTML, like Gecko) "
    "AdobeAIR/51.1"
)
DEFAULT_FLASH_VERSION = "51,1,3,10"
DEFAULT_ACCEPT = (
    "text/xml, application/xml, application/xhtml+xml, text/html;q=0.9, text/plain;q=0.8, "
    "text/css, image/png, image/jpeg, image/gif;q=0.8, application/x-shockwave-flash, "
    "video/mp4;q=0.9, flv-application/octet-stream;q=0.8, video/x-flv;q=0.7, audio/mp4, "
    "application/futuresplash, */*;q=0.5, application/x-mpegURL"
)

DEFAULT_HEADERS = {
    "Referer": DEFAULT_REFERER,
    "Accept": DEFAULT_ACCEPT,
    "x-flash-version": DEFAULT_FLASH_VERSION,
    "Content-Type": "application/x-amf",
    "User-Agent": DEFAULT_UA,
    "Accept-Encoding": "gzip,deflate",
    "Connection": "keep-alive",
}
