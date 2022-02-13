

local name, addon = ...

SamsUiTopBarMainMenuButtonMixin = {}

function SamsUiTopBarMainMenuButtonMixin:SetText(text)
    self.text:SetText(text)
end

function SamsUiTopBarMainMenuButtonMixin:SetIconAtlas(atlas)
    self.icon:SetAtlas(atlas)
end

function SamsUiTopBarMainMenuButtonMixin:OnLoad()
    self:SetAlpha(0)
end

function SamsUiTopBarMainMenuButtonMixin:OnShow()

    self.anim:Play()
    
end

function SamsUiTopBarMainMenuButtonMixin:OnHide()
    self:SetAlpha(0)
end

function SamsUiTopBarMainMenuButtonMixin:OnClick()
    if self.func then
        self.func()
    end
end