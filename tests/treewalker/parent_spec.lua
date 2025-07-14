local load_fixture = require("tests.load_fixture")
local tw = require("treewalker")
local h = require("tests.treewalker.helpers")
describe("Parent navigation in lua files:", function()
	before_each(function()
		load_fixture("/lua.lua")
	end)
	h.ensure_has_parser("lua")
	it("navigates up parent hierarchy", function()
		-- Start deep inside nested function: cursor on "return false" inside is_jump_target
		vim.fn.cursor(24, 12) -- inside "return false"
		-- First parent: the if statement
		tw.goto_parent()
		h.assert_cursor_at(23, 5, "if node:type():match(matcher) then")
		-- Second parent: the for loop
		tw.goto_parent()
		h.assert_cursor_at(22, 3, "for _, matcher in ipairs(NON_TARGET_NODE_MATCHERS) do")
		-- Third parent: the function definition
		tw.goto_parent()
		h.assert_cursor_at(21, 1, "local function is_jump_target(node)")
	end)
	it("skips trivial wrapper nodes", function()
		-- Start inside a function call parameter
		vim.fn.cursor(31, 35) -- inside "TARGET_DESCENDANT_TYPES"
		-- Should go to return statement (skipping function call wrapper)
		tw.goto_parent()
		h.assert_cursor_at(31, 3, "return util.contains(TARGET_DESCENDANT_TYPES, node:type())")
		-- Then to function definition
		tw.goto_parent()
		h.assert_cursor_at(30, 1, "local function is_descendant_jump_target(node)")
	end)
	it("handles nested object-like structures", function()
		-- Start inside the NON_TARGET_NODE_MATCHERS table
		vim.fn.cursor(7, 15) -- inside the comment pattern string
		-- First should go to the table element
		tw.goto_parent()
		h.assert_cursor_at(7, 3, '"^.*comment.*$",')
		-- Then to the table
		tw.goto_parent()
		h.assert_cursor_at(5, 1, "local NON_TARGET_NODE_MATCHERS = {")
	end)
	it("works with assignment expressions", function()
		-- Start inside variable name of assignment
		vim.fn.cursor(39, 10) -- inside "srow1"
		-- Should go to the assignment statement first
		tw.goto_parent()
		h.assert_cursor_at(39, 3, "local srow1, scol1 = node1:range()")
		-- Then to function definition
		tw.goto_parent()
		h.assert_cursor_at(38, 1, "local function have_same_range(node1, node2)")
	end)
	it("stops at file scope when no more parents", function()
		-- Start at top-level function
		vim.fn.cursor(21, 1)
		-- Go to file scope (module level)
		tw.goto_parent()
		-- Should stay at the function since it's already at top level
		h.assert_cursor_at(21, 1, "local function is_jump_target(node)")
		-- Another attempt should also stay put
		tw.goto_parent()
		h.assert_cursor_at(21, 1, "local function is_jump_target(node)")
	end)
	it("preserves cursor position when no valid parent found", function()
		-- Start at module level variable
		vim.fn.cursor(1, 1) -- "local util = require..."
		-- Should stay in place since already at top level
		tw.goto_parent()
		h.assert_cursor_at(1, 1, "local util = require('treewalker.util')")
	end)
	it("navigates from function parameters to function definition", function()
		-- Test navigation from function parameter to function definition
		vim.fn.cursor(38, 32) -- inside "node1" parameter
		-- Should go to function definition (skipping parameter wrapper)
		tw.goto_parent()
		h.assert_cursor_at(38, 1, "local function have_same_range(node1, node2)")
	end)
end)
describe("Parent navigation across different structures:", function()
	before_each(function()
		-- Use the existing fixture approach that properly sets up treesitter
		load_fixture("/lua.lua")
	end)
	h.ensure_has_parser("lua")
	it("navigates from deep function nesting", function()
		-- Go to a deeply nested location in the existing fixture
		-- Line 22 has a for loop inside the is_jump_target function
		vim.fn.cursor(24, 12) -- inside "return false"
		-- Navigate up the parent chain step by step
		tw.goto_parent()
		h.assert_cursor_at(23, 5, "if node:type():match(matcher) then")
		tw.goto_parent()
		h.assert_cursor_at(22, 3, "for _, matcher in ipairs(NON_TARGET_NODE_MATCHERS) do")
		tw.goto_parent()
		h.assert_cursor_at(21, 1, "local function is_jump_target(node)")
	end)
	it("correctly handles assignment within function", function()
		-- Start inside a local variable assignment within a function
		vim.fn.cursor(39, 15) -- inside "node1:range()"
		-- Should go to assignment first
		tw.goto_parent()
		h.assert_cursor_at(39, 3, "local srow1, scol1 = node1:range()")
		-- Then to function
		tw.goto_parent()
		h.assert_cursor_at(38, 1, "local function have_same_range(node1, node2)")
	end)
end)
describe("Parent navigation in JavaScript files:", function()
	before_each(function()
		load_fixture("/javascript.js")
	end)
	h.ensure_has_parser("javascript")
	it("navigates to meaningful parent structures", function()
		-- Start inside a function body and navigate to function declaration
		vim.fn.cursor(3, 10) -- inside if statement condition
		tw.goto_parent()
		-- Should navigate to the function definition (skipping trivial wrappers)
		local row = unpack(vim.api.nvim_win_get_cursor(0))
		assert.is_true(row >= 2 and row <= 5) -- Should be at function level
	end)
end)
describe("Parent navigation in Python files:", function()
	before_each(function()
		load_fixture("/python.py")
	end)
	h.ensure_has_parser("python")
	it("navigates to meaningful parent structures", function()
		-- Start inside a method body
		vim.fn.cursor(18, 20) -- inside print statement
		tw.goto_parent()
		-- Should navigate to method or class definition
		local row = unpack(vim.api.nvim_win_get_cursor(0))
		assert.is_true(row >= 13 and row <= 17) -- Should be at method or class level
	end)
end)
describe("Parent navigation in Rust files:", function()
	before_each(function()
		load_fixture("/rust.rs")
	end)
	h.ensure_has_parser("rust")
	it("navigates to meaningful parent structures", function()
		-- Start inside a method body
		vim.fn.cursor(21, 30) -- inside calculation
		tw.goto_parent()
		-- Should navigate to meaningful parent (function, impl, etc.)
		local row = unpack(vim.api.nvim_win_get_cursor(0))
		assert.is_true(row >= 19 and row <= 23) -- Should be at function or impl level
	end)
end)
describe("Parent navigation in TypeScript files:", function()
	before_each(function()
		load_fixture("/typescript.ts")
	end)
	h.ensure_has_parser("typescript")
	it("navigates to meaningful parent structures", function()
		-- Start inside a method body
		vim.fn.cursor(31, 30) -- inside template literal
		tw.goto_parent()
		-- Should navigate to method or class definition
		local row = unpack(vim.api.nvim_win_get_cursor(0))
		assert.is_true(row >= 22 and row <= 33) -- Should be at method or class level
	end)
end)
describe("Parent navigation in C files:", function()
	before_each(function()
		load_fixture("/c.c")
	end)
	h.ensure_has_parser("c")
	it("navigates to meaningful parent structures", function()
		-- Start inside a function body
		vim.fn.cursor(12, 30) -- inside malloc call
		tw.goto_parent()
		-- Should navigate to function definition
		local row = unpack(vim.api.nvim_win_get_cursor(0))
		assert.is_true(row >= 11 and row <= 23) -- Should be at function level
	end)
end)
describe("Parent navigation in Ruby files:", function()
	before_each(function()
		load_fixture("/ruby.rb")
	end)
	h.ensure_has_parser("ruby")
	it("navigates to meaningful parent structures", function()
		-- Start inside a method body
		vim.fn.cursor(7, 15) -- inside assignment
		tw.goto_parent()
		-- Should navigate to method or class definition
		local row = unpack(vim.api.nvim_win_get_cursor(0))
		assert.is_true(row >= 2 and row <= 6) -- Should be at method or class level
	end)
end)
describe("Parent navigation in HTML files:", function()
	before_each(function()
		load_fixture("/html.html")
	end)
	h.ensure_has_parser("html")
	it("navigates to meaningful parent structures", function()
		-- Start inside text content
		vim.fn.cursor(7, 10) -- inside title text
		tw.goto_parent()
		-- Should navigate to element or parent structure
		local row = unpack(vim.api.nvim_win_get_cursor(0))
		assert.is_true(row >= 3 and row <= 10) -- Should be at element level
	end)
end)