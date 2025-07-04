SrvDupeES.CachedImages = SrvDupeES.CachedImages or {}

local authorizedImageFormats = {
    "png",
    "jpg",
    "jpeg",
}

local function getDupeImageDir()
    local sanitizedIpAddress = string.gsub(game.GetIPAddress() or "0.0.0.0:0", ":", "_")

    local path = SrvDupeES.ImageFolder .. "/" .. sanitizedIpAddress
    if not file.Exists(path, "DATA") then
        file.CreateDir(path)
    end
    SrvDupeES.PathServerImages = path
    return path
end

local function isContentTypeImage(contentTypeHeader)
    local contentTypeHeader = string.lower(contentTypeHeader or "")
    for _, v in pairs(authorizedImageFormats) do
        if contentTypeHeader == "image/" .. v then
            return v
        end
    end
    return false
end

function SrvDupeES.GetImagePath(dupeId)
    local dupeImageDir = SrvDupeES.PathServerImages or getDupeImageDir()
    local pathNoExt = dupeImageDir .. "/" .. dupeId

    for _, ext in ipairs(authorizedImageFormats) do
        local path = pathNoExt .. "." .. ext
        if file.Exists(path, "DATA") then
            return path, ext
        end
    end
end

local function getImageFromURL(url, callBackSuccess)
    if not url or url == "" then
        return
    end

    http.Fetch(url, function(body, size, headers, code)
        print("[SrvDupeES]\tFetching image from URL: " .. url .. " - Status code: " .. code)
        if not body or body == "" then
            print("[SrvDupeES]\tError fetching image from URL: " .. url .. " - Received empty response")
        end

        local imageData = body
        local extension = isContentTypeImage(headers["Content-Type"] or headers["content-type"])
        if not extension then
            print("[SrvDupeES]\tInvalid image content from URL: " .. url .. "not a valid PNG or JPEG")
        else
            callBackSuccess(imageData, extension)
        end

    end, function(err)
        print("[SrvDupeES]\tError fetching image from URL: " .. url .. " - " .. err)
    end)
end

function SrvDupeES.AttemptGetImage(dupeId, dupeImageUrl, callBackSuccess)
    if not dupeId or not dupeImageUrl or dupeImageUrl == "" then
        return
    end

    local function saveImage(imageData, ext)
        if not imageData or imageData == "" then
            return
        end

        local path = (SrvDupeES.PathServerImages or getDupeImageDir()) .. "/" .. dupeId .. "." .. ext
        if path then
            file.Write(path, imageData)
            SrvDupeES.CachedImages[dupeId] = {
                Url = dupeImageUrl,
                Path = path
            }
            callBackSuccess(path)
        end
    end

    local cachedImage = SrvDupeES.CachedImages[dupeId]
    if cachedImage and file.Exists(cachedImage.Path, "DATA") and dupeImageUrl == cachedImage.Url then
        callBackSuccess(cachedImage.Path)
    else
        SrvDupeES.CachedImages[dupeId] = nil
        getImageFromURL(dupeImageUrl, saveImage)
    end
end