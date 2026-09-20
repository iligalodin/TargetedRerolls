return function(mod)
    assert(SMODS.load_file('src/mods/CRYPTID.lua'))()(mod)
    assert(SMODS.load_file('src/mods/AKYRS.lua'))()(mod)
end
