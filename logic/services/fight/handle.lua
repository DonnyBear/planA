

local function test(...)
	print("fight handle test ok")
	print(...)
end



function __init__()
	srv_iml.srv_test = test
end