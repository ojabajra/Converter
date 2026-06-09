from fastapi import FastAPI
from fastapi.responses import PlainTextResponse

app = FastAPI()

USAGE = """\
Number Base Converter API
=========================

Endpoint:
  GET /convert/<value>/<input-format>/<output-format>

Formats:
  dec  - Decimal (base 10)
  bin  - Binary  (base 2)
  hex  - Hexadecimal (base 16)

Examples:
  GET /convert/255/dec/hex   -> ff
  GET /convert/ff/hex/bin    -> 11111111
  GET /convert/1010/bin/dec  -> 10
"""

FORMATS = {"dec", "bin", "hex"}

BASE = {"dec": 10, "bin": 2, "hex": 16}

PREFIX = {"dec": "", "bin": "", "hex": ""}


def convert(value: str, input_fmt: str, output_fmt: str) -> str:
    n = int(value, BASE[input_fmt])
    if output_fmt == "dec":
        return str(n)
    elif output_fmt == "bin":
        return bin(n)[2:]
    else:  # hex
        return hex(n)[2:]


@app.get("/health", response_class=PlainTextResponse)
def health():
    return "OK"


@app.get("/convert/{value}/{input_fmt}/{output_fmt}", response_class=PlainTextResponse)
def convert_endpoint(value: str, input_fmt: str, output_fmt: str):
    if input_fmt not in FORMATS:
        return PlainTextResponse(
            f"Error: invalid input-format '{input_fmt}'. Must be one of: dec, bin, hex",
            status_code=400,
        )
    if output_fmt not in FORMATS:
        return PlainTextResponse(
            f"Error: invalid output-format '{output_fmt}'. Must be one of: dec, bin, hex",
            status_code=400,
        )
    try:
        result = convert(value, input_fmt, output_fmt)
        return result
    except ValueError:
        return PlainTextResponse(
            f"Error: '{value}' is not a valid {input_fmt} number",
            status_code=400,
        )


@app.get("/{full_path:path}", response_class=PlainTextResponse)
def fallback(full_path: str):
    return USAGE
