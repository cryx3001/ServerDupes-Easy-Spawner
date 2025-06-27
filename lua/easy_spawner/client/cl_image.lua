local authorizedImageFormats = {
    "png",
    "jpg",
    "jpeg",
}


local function isContentTypeImage(contentTypeHeader)
    local contentTypeHeader = string.lower(contentTypeHeader or "")
    for _, v in pairs(authorizedImageFormats) do
        if contentTypeHeader == "image/" .. v then
            return v
        end
    end
    return false
end

function SrvDupeES.AttemptGetImage(url, callBackSuccess)
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

local function getDupeImageDir()
    local ipAddress = game.GetIPAddress()
    local path = SrvDupeES.ImageFolder .. "/" .. ipAddress
    if not file.Exists(path, "DATA") then
        file.CreateDir(path)
    end
    return path
end

function SrvDupeES.CompareHashImageWithStored(path, sha1Hash, ext)
    local fileContent = file.Read(path, "DATA")
    if fileContent and fileContent ~= "" then
        local fileHash = util.SHA1(fileContent)
        if fileHash == sha1Hash then
            return true
        end
    end

    return false
end

function SrvDupeES.SaveImageIfNotExistsAndGet(dupeId, imageData, ext)
    if not dupeId or not imageData or imageData == "" then
        print("[SrvDupeES]\tCould not save image for " .. tostring(dupeId) .. ": the content may not be an image")
        return
    end

    local sha1Hash = util.SHA1(imageData)
    local path = getDupeImageDir() .. "/" .. dupeId .. "." .. ext
    if not SrvDupeES.CompareHashImageWithStored(path, sha1Hash) then
        file.Write(path, imageData)
        print("[SrvDupeES]\tSaved image for " .. dupeId .. " at " .. path)
    else
        print("[SrvDupeES]\tImage for " .. dupeId .. " at " .. path .. " already exists, skipping")
    end

    return path
end