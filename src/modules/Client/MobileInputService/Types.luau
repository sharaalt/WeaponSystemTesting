export type unbind = () -> ()
type setTitle = (self: {}, title: string) -> ()
type setImage = (self: {}, imageAsset: string) -> ()
type setPosition = (self: {}, position: UDim2) -> ()
type getButton = (self: {}) -> ()

export type cacheTable = {
	Name: string,
	Id: number,
	InputEnum: EnumItem,

	Unbind: unbind,
	SetTitle: setTitle,
	SetImage: setImage,
	SetPosition: setPosition,
	GetButton: getButton,
}

local Types = {}

return Types
