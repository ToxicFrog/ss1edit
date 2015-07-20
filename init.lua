local name = (...):gsub("%.init$", "")

require (name..'.flags')
require (name..'.io')
require (name..'.logging')
require (name..'.math')
require (name..'.misc')
require (name..'.string')
require (name..'.table')

if lfs then
	require (name..'.lfs')
end
