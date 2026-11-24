--[=[
    Utility module for dealing with the `game.Content` API.

    Written by Turing6.

    @class ContentUtils
]=]
const ContentUtils = {}

const Promise = require("./Promise")

--[=[
    Promise wrapper for `game.Content.Fetch`

    @function fetch
    @param id string
    @param sha256 string?
    @return Promise<(ContentAsset), (string)>
]=]
function ContentUtils.fetch(id: string, sha256: string?): Promise.Promise<(ContentAsset), (string)>
    return Promise.new(function(resolve: (ContentAsset) -> (), reject: (string) -> (), onCancel: (cancelHandler: () -> ()) -> ())
        local request: ContentRequest = game.Content.Fetch(id, sha256, function(asset: ContentAsset?, err: string?)
            if asset then
                resolve(asset)
            else
                reject(err)
            end
        end)

        onCancel(function()
            if request.Pending then
                request:Cancel()
            end
        end)
    end)
end

--[=[
    Promise wrapper for `game.Content.Avatar`

    @function avatar
    @param player Instance
    @return Promise<(AvatarManifest), (string)>
]=]
function ContentUtils.avatar(player: Instance): Promise.Promise<(AvatarManifest), (string)>
    return Promise.new(function(resolve: (AvatarManifest) -> (), reject: (string) -> (), onCancel: (cancelHandler: () -> ()) -> ())
        local request: ContentRequest = game.Content.Avatar(player, function(avatar: AvatarManifest?, err: string?)
            if not avatar then
                err = if err then err else "Unable to fetch avatar for non-account player"
                reject(err)
            else
                resolve(avatar)
            end
        end)

        onCancel(function()
            if request.Pending then
                request:Cancel()
            end
        end)
    end)
end

return ContentUtils