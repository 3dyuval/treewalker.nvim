local load_fixture = require("tests.load_fixture")
local tw = require("treewalker")
local helpers = require("tests.treewalker.helpers")

describe("When opts.jumplist = true (default behavior)", function()
	it("move_down adds jumps to jumplist", function()
		tw.setup()
		load_fixture("/lua-spec.lua")
		vim.cmd("windo clearjumps")
		vim.fn.cursor(108, 1)

		-- This step is a bummer.
		-- It's hard to check for single line moves, while still adding one entry
		-- to the jumplist at the _first move_. Which is the first move? Hopefully
		-- a clever way reveals itself, because all I can think of now is on every
		-- move, checking every line between us and the next jump list entry and
		-- seeing if they would all be single line moves. But all of a sudden every
		-- move needs to do this operation that multiplies its efforts.
		-- So for now we'll mark both the origin and the destination.
		tw.move_in()

		-- Move down a bunch
		helpers.assert_cursor_at(109, 3, "|local range1")
		for _ = 1, 10, 1 do
			tw.move_down()
		end
		helpers.assert_cursor_at(129, 3, "|vim.lsp.util")

		-- Unwind jumplist
		helpers.feed_keys("<C-o>")
		helpers.assert_cursor_at(120, 3, "|it(two)")

		helpers.feed_keys("<C-o>")
		helpers.assert_cursor_at(117, 3, "|local edit1")

		helpers.feed_keys("<C-o>")
		helpers.assert_cursor_at(115, 3)

		helpers.feed_keys("<C-o>")
		helpers.assert_cursor_at(114, 3)

		helpers.feed_keys("<C-o>")
		helpers.assert_cursor_at(112, 3)

		helpers.feed_keys("<C-o>")
		helpers.assert_cursor_at(109, 3)

		helpers.feed_keys("<C-o>")
		helpers.assert_cursor_at(108, 1)
	end)

	it("move_up adds jumps to jumplist", function()
		load_fixture("/lua-spec.lua")
		vim.cmd("windo clearjumps")
		vim.fn.cursor(122, 5) -- part way into it block
		tw.move_out()

		-- move up a bunch
		helpers.assert_cursor_at(120, 3, "|it")
		for _ = 1, 9, 1 do
			tw.move_up()
		end
		helpers.assert_cursor_at(109, 3, "|local range1")

		-- unwind jumplist
		helpers.feed_keys("<C-o>")
		helpers.assert_cursor_at(114, 3, "|local text1")

		helpers.feed_keys("<C-o>")
		helpers.assert_cursor_at(117, 3, "|local edit1")

		helpers.feed_keys("<C-o>")
		helpers.assert_cursor_at(120, 3, "|it")

		helpers.feed_keys("<C-o>")
		helpers.assert_cursor_at(122, 5, "|tree")
	end)

	it("move_in adds single line jumps to the jumplist", function()
		load_fixture("/lua.lua")
		vim.cmd("windo clearjumps")
		vim.fn.cursor(21, 1)
		tw.move_in()
		helpers.assert_cursor_at(22, 3, "for _,")
		helpers.feed_keys("<C-o>")
		helpers.assert_cursor_at(21, 1, "local function is_jump_target")
	end)

	it("move_out adds single line jumps to the jumplist", function()
		load_fixture("/lua.lua")
		vim.cmd("windo clearjumps")
		vim.fn.cursor(132, 3)
		tw.move_out()
		helpers.assert_cursor_at(128, 1)
		helpers.feed_keys("<C-o>")
		helpers.assert_cursor_at(132, 3)
	end)

	it("move_down doesn't add single line jumps to the jumplist", function()
		load_fixture("/lua.lua")
		vim.cmd("windo clearjumps")
		vim.fn.cursor(128, 1)
		tw.move_in()
		tw.move_down()
		tw.move_down()
		tw.move_down()
		tw.move_down()
		helpers.assert_cursor_at(136, 3)
		helpers.feed_keys("<C-o>")
		helpers.assert_cursor_at(132, 3)
		helpers.feed_keys("<C-o>")
		helpers.assert_cursor_at(129, 3)
	end)

	it("move_up doesn't add single line jumps to the jumplist", function()
		load_fixture("/lua.lua")
		vim.cmd("windo clearjumps")
		vim.fn.cursor(133, 5)
		tw.move_out()
		tw.move_up()
		tw.move_up()
		tw.move_up()
		helpers.assert_cursor_at(129, 3)
		helpers.feed_keys("<C-o>")
		helpers.assert_cursor_at(132, 3)
		helpers.feed_keys("<C-o>")
		helpers.assert_cursor_at(133, 5)
	end)
end)

describe("When opts.jumplist = false", function()
	before_each(function()
		tw.setup({ jumplist = false })
		load_fixture("/lua.lua")
		vim.cmd("windo clearjumps")
	end)

	it("move_down does NOT add to jumplist", function()
		vim.fn.cursor(10, 1)
		tw.move_down()
		local jumplist_count = #vim.fn.getjumplist()[1]
		assert.equals(0, jumplist_count)
		helpers.feed_keys("<C-o>")
		helpers.assert_cursor_at(21, 1)
	end)

	it("move_up does NOT add to jumplist", function()
		load_fixture("/lua.lua")
		vim.cmd("windo clearjumps")
		vim.fn.cursor(10, 1)
		tw.move_up()
		local jumplist_count = #vim.fn.getjumplist()[1]
		assert.equals(0, jumplist_count)
		helpers.feed_keys("<C-o>")
		helpers.assert_cursor_at(5, 1)
	end)

	it("move_out does NOT add to jumplist", function()
		vim.fn.cursor(80, 5)
		tw.move_out()
		helpers.assert_cursor_at(79, 1)
		local jumplist_count = #vim.fn.getjumplist()[1]
		assert.equals(0, jumplist_count)
		helpers.feed_keys("<C-o>")
		helpers.assert_cursor_at(79, 1)
	end)

	it("move_in does NOT add to jumplist", function()
		vim.fn.cursor(80, 5)
		tw.move_in()
		helpers.assert_cursor_at(83, 5)
		local jumplist_count = #vim.fn.getjumplist()[1]
		assert.equal(0, jumplist_count)
		helpers.feed_keys("<C-o>")
		helpers.assert_cursor_at(83, 5)
	end)
end)

describe("When opts.jumplist = 'left'", function()
	before_each(function()
		tw.setup({ jumplist = "left" })
		load_fixture("/lua.lua")
		vim.cmd("windo clearjumps")
	end)

	it("move_out adds to jumplist", function()
		vim.fn.cursor(80, 5)
		tw.move_out()
		helpers.assert_cursor_at(79, 1)
		local jumplist_count = #vim.fn.getjumplist()[1]
		assert(jumplist_count == 1)
		helpers.feed_keys("<C-o>")
		helpers.assert_cursor_at(80, 3)
	end)

	it("move_in does NOT add to jumplist", function()
		vim.fn.cursor(80, 5)
		tw.move_in()
		helpers.assert_cursor_at(83, 5)
		local jumplist_count = #vim.fn.getjumplist()[1]
		assert.equal(0, jumplist_count)
		helpers.feed_keys("<C-o>")
		helpers.assert_cursor_at(83, 5)
	end)

	it("move_up does NOT add to jumplist", function()
		vim.fn.cursor(79, 1)
		tw.move_up()
		helpers.assert_cursor_at(64, 1)
		local jumplist_count = #vim.fn.getjumplist()[1]
		assert.equal(0, jumplist_count)
		helpers.feed_keys("<C-o>")
		helpers.assert_cursor_at(64, 1)
	end)

	it("move_down does NOT add to jumplist", function()
		load_fixture("/lua.lua")
		vim.cmd("windo clearjumps")
		vim.fn.cursor(64, 1)
		tw.move_down()
		local jumplist_count = #vim.fn.getjumplist()[1]
		assert.equal(0, jumplist_count)
		helpers.feed_keys("<C-o>")
		helpers.assert_cursor_at(79, 1)
	end)
end)
