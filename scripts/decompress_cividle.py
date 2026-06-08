#!/usr/bin/env python3
import sys
import zlib
import json

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 decompress_cividle.py <save_file>", file=sys.stderr)
        sys.exit(1)
        
    filename = sys.argv[1]
    
    try:
        with open(filename, "rb") as f:
            compressed_data = f.read()
    except Exception as e:
        print(f"Error reading file '{filename}': {e}", file=sys.stderr)
        sys.exit(1)
        
    try:
        # Raw deflate uses wbits=-15
        decompressed_bytes = zlib.decompress(compressed_data, -15)
    except Exception as e:
        print(f"Error decompressing '{filename}': {e}", file=sys.stderr)
        print("Please verify this is a valid CivIdle save file.", file=sys.stderr)
        sys.exit(1)
        
    try:
        # Load and pretty-print the JSON
        save_json = json.loads(decompressed_bytes.decode("utf-8"))
        print(json.dumps(save_json, indent=2))
    except BrokenPipeError:
        # Devnull/BrokenPipe when using commands like head, exit gracefully
        try:
            sys.stdout.close()
        except OSError:
            pass
        sys.exit(0)
    except Exception as e:
        # In case the JSON parsing fails, output raw string
        print(f"Warning: Failed to parse as JSON ({e}). Outputting raw decompressed data.", file=sys.stderr)
        try:
            print(decompressed_bytes.decode("utf-8"))
        except BrokenPipeError:
            sys.exit(0)
        except Exception as decode_err:
            try:
                sys.stdout.buffer.write(decompressed_bytes)
            except BrokenPipeError:
                sys.exit(0)

if __name__ == "__main__":
    main()
