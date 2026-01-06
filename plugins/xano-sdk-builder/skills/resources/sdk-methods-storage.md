# SDK Storage & File Methods

File upload, download, metadata, image processing, and media operations.

## Table of Contents
- [File Upload/Download](#file-uploaddownload)
- [File Metadata](#file-metadata)
- [File Operations](#file-operations)
- [Media (Image, Video, Audio)](#media-image-video-audio)
- [File Resources](#file-resources)
- [Image Processing](#image-processing)

---

## File Upload/Download

**3 methods** for basic file operations.

| Method | Params | Returns | Purpose |
|--------|--------|---------|---------|
| `storageUpload(file,folder,alias)` | file:any, folder:string, alias:string | this | Upload file |
| `storageS3Download(uri,alias?)` | uri:string, alias?:string | this | Download file from S3 |
| `deleteFile(pathname)` | pathname:string | this | Delete file |

### Examples

```json
{
  "operations": [
    {"method": "storageUpload", "args": ["$input.file", "uploads", "uploaded_file"]},
    {"method": "storageS3Download", "args": ["$file_uri", "file_data"]},
    {"method": "deleteFile", "args": ["/uploads/old-file.jpg"]}
  ]
}
```

---

## File Metadata

**4 methods** for file metadata operations.

| Method | Params | Returns | Purpose |
|--------|--------|---------|---------|
| `storageGetMetadata(path,alias?)` | path:string, alias?:string | this | Get file metadata |
| `storageUpdateMetadata(path,metadata,alias?)` | path:string, metadata:any, alias?:string | this | Update metadata |
| `storageGenerateUrl(path,type?,alias?)` | path:string, type?:'public'\|'signed', alias?:string | this | Generate file URL |
| `signPrivateUrl(pathname,ttl,alias)` | pathname:string, ttl:number, alias:string | this | Sign private URL |

### Examples

```json
{
  "operations": [
    {"method": "storageGetMetadata", "args": ["/uploads/file.jpg", "metadata"]},
    {"method": "storageGenerateUrl", "args": ["/private/file.pdf", "signed", "url"]},
    {"method": "signPrivateUrl", "args": ["/private/doc.pdf", 3600, "signed_url"]}
  ]
}
```

---

## File Operations

**4 methods** for file management.

| Method | Params | Returns | Purpose |
|--------|--------|---------|---------|
| `storageCopy(source,destination,alias?)` | source:string, destination:string, alias?:string | this | Copy file |
| `storageMove(source,destination,alias?)` | source:string, destination:string, alias?:string | this | Move/rename file |
| `storageCreateFolder(path,alias?)` | path:string, alias?:string | this | Create folder |
| `storageDeleteFolder(path,alias?)` | path:string, alias?:string | this | Delete folder |

### Examples

```json
{
  "operations": [
    {"method": "storageCopy", "args": ["/uploads/original.jpg", "/backups/original.jpg", "copied"]},
    {"method": "storageMove", "args": ["/temp/file.pdf", "/permanent/file.pdf", "moved"]},
    {"method": "storageCreateFolder", "args": ["/uploads/2024", "created"]}
  ]
}
```

---

## Media (Image, Video, Audio)

**7 methods** for creating media resources.

| Method | Params | Returns | Purpose |
|--------|--------|---------|---------|
| `storageCreateImage(fileIdOrConfig,access?,alias?)` | fileIdOrConfig:string\|any, access?:string, alias?:string | this | Create image resource |
| `createImage(access,value,filename,alias?,options?)` | access:'public'\|'private', value:string, filename:string, alias?:string, options?:any | this | Create image |
| `storageCreateVideo(valueOrConfig,access?,alias?)` | valueOrConfig:string\|any, access?:string, alias?:string | this | Create video resource |
| `createVideo(access,value,filename,alias?,options?)` | access:'public'\|'private', value:string, filename:string, alias?:string, options?:any | this | Create video |
| `storageCreateAudio(valueOrConfig,access?,alias?)` | valueOrConfig:string\|any, access?:string, alias?:string | this | Create audio resource |
| `createAudio(access,value,filename,alias?,options?)` | access:'public'\|'private', value:string, filename:string, alias?:string, options?:any | this | Create audio |
| `createAttachment(access,value,filename,alias?)` | access:'public'\|'private', value:string, filename:string, alias?:string | this | Create attachment |

### Examples

```json
{
  "operations": [
    {"method": "createImage", "args": ["public", "$input.image", "profile.jpg", "image"]},
    {"method": "createVideo", "args": ["private", "$input.video", "recording.mp4", "video"]},
    {"method": "createAudio", "args": ["public", "$input.audio", "podcast.mp3", "audio"]}
  ]
}
```

---

## File Resources

**6 methods** for file resource management.

| Method | Params | Returns | Purpose |
|--------|--------|---------|---------|
| `createFile(visibility,file,path,alias)` | visibility:string, file:string, path:string, alias:string | this | Create file |
| `createFileResource(filename,filedata,alias?)` | filename:string, filedata:string, alias?:string | this | Create from data |
| `storageCreateFile(filename,content,alias)` | filename:string, content:string, alias:string | this | Create file with content |
| `readFileResource(value,alias?)` | value:string, alias?:string | this | Read file content |
| `storageCreateFromUrl(url,access,filename,alias?)` | url:string, access:'public'\|'private', filename:string, alias?:string | this | Create from URL |
| `storageGetUrl(fileId,alias?)` | fileId:string, alias?:string | this | Get file URL |

### Examples

```json
{
  "operations": [
    {"method": "storageCreateFromUrl", "args": ["https://example.com/image.jpg", "public", "imported.jpg", "file"]},
    {"method": "storageCreateFile", "args": ["data.json", "{\"key\": \"value\"}", "created_file"]},
    {"method": "storageGetUrl", "args": ["$file.id", "url"]}
  ]
}
```

---

## Image Processing

**3 methods** for image manipulation.

| Method | Params | Returns | Purpose |
|--------|--------|---------|---------|
| `storageGenerateThumbnail(sourceOrConfig,destination?,alias?)` | sourceOrConfig:string\|any, destination?:string, alias?:string | this | Generate thumbnail |
| `imageResize(image,dimensions,alias)` | image:any, dimensions:{width?:number;height?:number}, alias:string | this | Resize image |
| `imageOptimize(image,quality,alias)` | image:any, quality:number, alias:string | this | Optimize image |

### Examples

```json
{
  "operations": [
    {"method": "storageGenerateThumbnail", "args": ["/uploads/photo.jpg", "/uploads/thumb.jpg", "thumb"]},
    {"method": "imageResize", "args": ["$image", {"width": 800, "height": 600}, "resized"]},
    {"method": "imageOptimize", "args": ["$image", 85, "optimized"]}
  ]
}
```

---

**Total Methods in this File: 27**

**Verification Status:**
- Last verified: 2025-01-13
- Method name correction: `storageS3Download()` (was incorrectly documented as `storageDownload()`)

For workflow guidance, see [workflow.md](workflow.md)
For complete examples, see [examples.md](examples.md)
