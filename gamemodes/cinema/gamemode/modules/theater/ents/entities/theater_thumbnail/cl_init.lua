﻿-- This file is subject to copyright - contact swampservers@gmail.com for more information.
-- INSTALL: CINEMA
include('sh_init.lua')
ENT.RenderGroup = RENDERGROUP_BOTH

surface.CreateFont("TheaterInfoLarge", {
    font = "Open Sans Condensed",
    size = 130,
    weight = 700,
    antialias = true
})

surface.CreateFont("TheaterInfoMedium", {
    font = "Open Sans Condensed",
    size = 72,
    weight = 700,
    antialias = true
})

function ENT:Initialize()
    local bound = Vector(1, 1, 1) * 1024
    self:SetRenderBounds(-bound, bound)
end

function ENT:Draw()
    self:DrawModel()
end

local ThumbWidth = 480
local ThumbHeight = 360
local RenderScale = 0.2
local AngleOffset = Angle(0, 90, 90)

function ENT:DrawTranslucent()
    -- Find attachment
    if not self.Attach then
        local attachId = self:LookupAttachment("thumb3d2d")
        self.Attach = self:GetAttachment(attachId)

        if self.Attach then
            self.Attach.Ang = self.Attach.Ang + AngleOffset
        else
            return
        end
    end

    cam.Start3D2D(self.Attach.Pos, self.Attach.Ang, RenderScale)
    self:DrawThumbnail()
    cam.End3D2D()
    self:DrawText()


    if self.Attach and self:GetNWBool("Rentable") then
        local thumbWidth = 480
        local thumbHeight = 360
        local renderScale = 0.2

        location = self:GetNWInt("Location")
        local tb = protectedTheaterTable[location]

        if tb ~= nil and tb["time"] > 1 then
            surface.SetFont("TheaterInfoMedium")
            str = "Protected"
            tw, th = surface.GetTextSize(str)
            tw = tw + tw * 0.05
            scale = tw / thumbWidth
            scale = math.max(scale, 0.88)
            bw, bh = (thumbWidth * scale), (thumbHeight * scale) * 0.16
            bh = math.max(bh, th)
            by = (thumbHeight * scale)
            ty = by + (th / 2)
            cam.Start3D2D(self.Attach.Pos, self.Attach.Ang, (1 / scale) * renderScale)
            surface.SetDrawColor(0, 0, 0, 200)
            surface.DrawRect(0, by, bw, bh)
            draw.TheaterText(str, "TheaterInfoMedium", (thumbWidth * scale) / 2, ty, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            cam.End3D2D()
        end
    end
end

local hangs = {"p", "g", "y", "q", "j"}

local tw, th, ty, scale, bw, bh, by = nil

function ENT:DrawSubtitle(str, height)
    surface.SetFont("TheaterInfoMedium")

    self.TextSizeCache = self.TextSizeCache or defaultdict(
        function(str) 
            surface.SetFont("TheaterInfoMedium")
            tw, th = surface.GetTextSize(str)
            tw = tw * 1.05 
            if string.findFromTable(str, hangs) then
                th = th *1.15
            end
            return {tw,th}
        end
    )  

    tw,th = unpack(self.TextSizeCache[str])
    scale = math.max(tw / ThumbWidth, 0.88)
    bw, bh = (ThumbWidth * scale), (ThumbHeight * scale) * 0.16
    bh = math.max(bh, th)
    by = height * scale
    by = math.min(by, (ThumbHeight * scale) - bh)
    ty = (height * scale) + (bh / 2)
    ty = math.min(ty, (ThumbHeight * scale) - bh / 2)
    if cam.StartCulled3D2D(self.Attach.Pos, self.Attach.Ang, (1 / scale) * RenderScale) then
        surface.SetDrawColor(0, 0, 0, 200)
        surface.DrawRect(0, by, bw, bh)
        draw.TheaterText(str, "TheaterInfoMedium", (ThumbWidth * scale) / 2, ty, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        cam.End3D2D()
    end
end

local name, title
local CurrentName, CurrentTitle
local TranslatedName, TranslatedTitle

function ENT:DrawText()
    name = self:GetTheaterName()
    title = self:GetTitle()

    -- Name has changed
    if name ~= CurrentName then
        CurrentName = name
        TranslatedName = name

        if name == 'Invalid' then
            TranslatedName = T'Invalid'
        end
    end

    -- Title has changed
    if title ~= CurrentTitle then
        CurrentTitle = title
        TranslatedTitle = title

        if title == 'NoVideoPlaying' then
            TranslatedTitle = T'NoVideoPlaying'
        end
    end

    self:DrawSubtitle(TranslatedName, 0)
    self:DrawSubtitle(TranslatedTitle, 303)
end

net.Receive("ThumbnailDelivery", function(len)
    local thumbent = net.ReadEntity()

    if IsValid(thumbent) then
        thumbent.thumbnail = net.ReadString()
    end
end)

local DefaultThumbnail = Material("theater/static.vmt")

function ENT:OnRemoveHTML()
    --Msg("AWESOMIUM: Destroyed instance for video thumbnail: ")
    --Msg(self:GetThumbnail())
    --Msg("\n")
end

function ENT:DrawThumbnail()
    if (self.thumbnail == nil) then
        net.Start("ThumbnailDelivery")
        net.WriteEntity(self)
        net.SendToServer()
        self.thumbnail = ""
    end

    if (self:GetTitle() == "Nothing Playing") then
        self.thumbnail = ""
    end

    -- Thumbnail isn't set yet
    if self.thumbnail == "" or ((theater.Services[self:GetService()] and theater.Services[self:GetService()].Mature) and not GetConVar("swamp_mature_content"):GetBool()) then
        if self:GetService() == "" then
            surface.SetDrawColor(80, 80, 80)
            surface.SetMaterial(DefaultThumbnail)
            surface.DrawTexturedRect(0, 0, ThumbWidth - 1, ThumbHeight - 1)
        else
            surface.SetDrawColor(0, 0, 0)
            surface.DrawRect(0, 0, ThumbWidth - 1, ThumbHeight - 1)
            local str = self:GetService():upper()
            local hhh = 150 + math.sin(SysTime()) * 30.0
            local www = math.sin(SysTime() * 0.5) * 30.0
            --bunch of copy pasted garbage
            surface.SetFont("TheaterInfoMedium")
            -- Get text dimensions
            tw, th = surface.GetTextSize(str)
            tw = tw + tw * 0.05 -- add additional padding

            -- Calculate hangs
            if string.findFromTable(str, hangs) then
                th = th + (th / 6)
            end

            -- Calculate scale for fitting text
            scale = tw / ThumbWidth
            scale = math.max(scale, 0.88)
            -- Calculate subtitle bar dimensions
            bw, bh = (ThumbWidth * scale), (ThumbHeight * scale) * 0.16
            bh = math.max(bh, th)
            -- Calculate height offset for bar
            by = hhh * scale
            by = math.min(by, (ThumbHeight * scale) - bh)
            -- Calculate height offset for text
            ty = (hhh * scale) + (bh / 2)
            ty = math.min(ty, (ThumbHeight * scale) - bh / 2)
            cam.Start3D2D(self.Attach.Pos, self.Attach.Ang, (1 / scale) * RenderScale)
            draw.TheaterText(str, "TheaterInfoLarge", www + ((ThumbWidth * scale) / 2), ty, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            cam.End3D2D()
            --end of copy pasted garbage
        end

        return
    else -- Thumbnail is valid
        -- URL has changed
        if (not self.LastURL or self.LastURL ~= self.thumbnail) then
            if ValidPanel(self.HTML) then
                self:OnRemoveHTML()
                self.HTML:Remove()
            end

            self.LastURL = self.thumbnail
            self.ThumbMat = nil
        elseif self.LastURL and not self.ThumbMat then
            if not ValidPanel(self.HTML) then
                -- Create HTML panel to load thumbnail
                self.HTML = vgui.Create("Awesomium")
                self.HTML:SetSize(ThumbWidth, ThumbHeight)
                self.HTML:SetPaintedManually(true)
                self.HTML:SetKeyBoardInputEnabled(false)
                self.HTML:SetMouseInputEnabled(false)
                self.HTML:SetHTML([[
				    <html>
				    <body style="margin: 0;">
				        <img src="]] .. string.JavascriptSafe(self.thumbnail) .. [[" width="100%" height="100%"/>
				    </body>
				    </html>
				]])
                --Msg("AWESOMIUM: Initialized instance for video thumbnail: ")
                --Msg(self:GetThumbnail())
                --Msg("\n")
            elseif not self.HTML:IsLoading() and not self.JSDelay then
                -- Force thumbnail sizes
                self.HTML:RunJavascript([[
					var nodes = document.getElementsByTagName('img');
					for (var i = 0; i < nodes.length; i++) {
						nodes[i].style.width = '100%';
						nodes[i].style.height = '100%';
					}
				]])
                self.JSDelay = true

                -- Add delay to wait for JS to run
                timer.Simple(0.1, function()
                    if not IsValid(self) then return end
                    if not ValidPanel(self.HTML) then return end
                    -- Grab HTML material
                    self.HTML:UpdateHTMLTexture()
                    self.ThumbMat = self.HTML:GetHTMLMaterial()
                    -- Do some math to get the correct size
                    local pw, ph = self.HTML:GetSize()
                    -- Convert to scalar
                    self.w = ThumbWidth / pw
                    self.h = ThumbHeight / ph
                    -- Fix for non-power-of-two html panel size
                    pw = pw * (math.power2(pw) / pw)
                    ph = ph * (math.power2(ph) / ph)
                    self.w = self.w * pw
                    self.h = self.h * ph
                    -- Free resources after grabbing material
                    self:OnRemoveHTML()
                    self.HTML:Remove()
                    self.JSDelay = nil
                end)
            else
                -- Waiting for download to finish
                return
            end
        end
    end

    -- Draw the HTML material
    if self.ThumbMat then
    surface.SetDrawColor(255, 255, 255)
    surface.SetMaterial(self.ThumbMat)
    surface.DrawTexturedRect(0, 0, self.w - 1, self.h - 1)
    end
end