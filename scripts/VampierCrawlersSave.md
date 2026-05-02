# Vampire Crawlers Save Checksum

## Summary

Steam save files are JSON wrappers with this shape:

```json
{
  "Version": 1,
  "Checksum": "...",
  "Data": {
    "...": "..."
  }
}
```

The `Checksum` field is computed as:

```text
Base64( SHA1( UTF8Bytes(data) ) )
```

Here, `data` is the raw standalone save JSON string that the game passes into `FileSystemSaveHandler.Save`, not the entire wrapped `.save` file.

## Formatting Details

The checksum input uses:

- UTF-8 bytes
- SHA-1 digest
- Base64 encoding of the 20-byte SHA-1 digest
- CRLF line endings (`\r\n`)
- Normal 2-space JSON indentation for the standalone `Data` object

In the Steam `.save` file, the `Data` object is nested inside the wrapper, so it appears indented one extra level. To recompute the checksum from a wrapped Steam save:

1. Extract the `Data` JSON object.
2. Remove the wrapper's extra two-space indentation from each line.
3. Convert line endings to CRLF (`\r\n`).
4. Hash that resulting string with SHA-1 over UTF-8 bytes.
5. Base64-encode the hash bytes.

## Python Example

```python
import base64
import hashlib

checksum = base64.b64encode(
    hashlib.sha1(data.encode("utf-8")).digest()
).decode()
```

If starting from a wrapped `.save` file, `data` must be the unwrapped and correctly formatted `Data` JSON string described above.

## Confirmed In Game Code

The relevant IL2CPP method is:

```csharp
Nosebleed.PlatformManager.Backends.Common.Backends.Common.FileSystemSaveHandler
private string CalculateChecksum(string data)
```

From the IL2CPP dump:

```text
RVA: 0x2590650
Offset: 0x258F650
VA: 0x182590650
```

The disassembly shows this call sequence inside `CalculateChecksum`:

```text
System.Text.Encoding::get_UTF8
System.Text.Encoding::GetBytes(data)
System.Security.Cryptography.SHA1Managed::.ctor
System.Security.Cryptography.HashAlgorithm::ComputeHash
System.Convert::ToBase64String
```

So the implementation is equivalent to:

```csharp
private string CalculateChecksum(string data)
{
    byte[] bytes = Encoding.UTF8.GetBytes(data);
    using var sha1 = new SHA1Managed();
    return Convert.ToBase64String(sha1.ComputeHash(bytes));
}
```

## Verified Example

For `SaveProfile0.save`, the stored checksum was:

```text
HxuNMn4c3feS5VXnHFL0yi3H1cw=
```

Base64-decoding that gives this SHA-1 hex digest:

```text
1f1b8d327e1cddf792e555e71c52f4ca2dc7d5cc
```

That matches SHA-1 over the unwrapped `Data` JSON using CRLF line endings.
