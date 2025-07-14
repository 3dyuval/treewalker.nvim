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

	it("navigates from nested callback to function", function()
		-- Start inside nested callback: cursor on "callback(null, moreProcessedData);"
		vim.fn.cursor(50, 30) -- inside nested callback call
		
		-- First parent: arrow function
		tw.goto_parent()
		h.assert_cursor_at(48, 5, "processMoreData(processedData, (err, moreProcessedData) => {")
		
		-- Second parent: arrow function
		tw.goto_parent() 
		h.assert_cursor_at(46, 3, "processData(data, (err, processedData) => {")
		
		-- Third parent: arrow function
		tw.goto_parent()
		h.assert_cursor_at(44, 1, "fetchData((err, data) => {")
	end)

	it("navigates from function parameter to function definition", function()
		-- Start inside function parameter
		vim.fn.cursor(2, 25) -- inside "err" parameter
		
		-- Should go to function definition
		tw.goto_parent()
		h.assert_cursor_at(2, 1, "function myCallback1(err, data) {")
	end)

	it("navigates from object property to object literal", function()
		-- Start inside object property value
		vim.fn.cursor(19, 25) -- inside 'bar' string
		
		-- Should go to object literal
		tw.goto_parent()
		h.assert_cursor_at(19, 17, "const data = { foo: 'bar' };")
	end)

	it("navigates from setTimeout callback to containing function", function()
		-- Start inside setTimeout callback
		vim.fn.cursor(20, 15) -- inside "callback(null, data);"
		
		-- Should go to arrow function
		tw.goto_parent()
		h.assert_cursor_at(18, 3, "setTimeout(() => {")
		
		-- Then to function definition
		tw.goto_parent()
		h.assert_cursor_at(17, 1, "function fetchData(callback) {")
	end)
end)

describe("Parent navigation in Python files:", function()
	before_each(function()
		load_fixture("/python.py")
	end)

	h.ensure_has_parser("python")

	it("navigates from method body to class definition", function()
		-- Start inside method body: cursor on print statement
		vim.fn.cursor(18, 20) -- inside "Hello, my name is {self.name}!"
		
		-- First parent: method definition
		tw.goto_parent()
		h.assert_cursor_at(17, 5, "def greet(self):")
		
		-- Second parent: class definition
		tw.goto_parent()
		h.assert_cursor_at(13, 1, "class Person:")
	end)

	it("navigates from decorator to function definition", function()
		-- Start inside decorator
		vim.fn.cursor(28, 10) -- inside "@random_annotation"
		
		-- Should go to class definition
		tw.goto_parent()
		h.assert_cursor_at(29, 1, "class Car:")
	end)

	it("navigates from nested function to outer function", function()
		-- Start inside wrapper function print statement
		vim.fn.cursor(8, 15) -- inside print statement
		
		-- First parent: wrapper function
		tw.goto_parent()
		h.assert_cursor_at(6, 5, "def wrapper(*args, **kwargs):")
		
		-- Second parent: decorator function
		tw.goto_parent()
		h.assert_cursor_at(4, 1, "def random_annotation(func):")
	end)

	it("navigates from try-except block to method", function()
		-- Start inside try block
		vim.fn.cursor(73, 20) -- inside "self.tasks[task_number - 1]"
		
		-- First parent: try statement
		tw.goto_parent()
		h.assert_cursor_at(72, 9, "try:")
		
		-- Second parent: method definition
		tw.goto_parent()
		h.assert_cursor_at(71, 5, "def mark_task_complete(self, task_number):")
		
		-- Third parent: class definition
		tw.goto_parent()
		h.assert_cursor_at(54, 1, "class TodoList:")
	end)

	it("navigates from f-string to method", function()
		-- Start inside f-string
		vim.fn.cursor(36, 30) -- inside f-string
		
		-- Should go to method definition
		tw.goto_parent()
		h.assert_cursor_at(35, 5, "def display_info(self):")
		
		-- Then to class definition
		tw.goto_parent()
		h.assert_cursor_at(29, 1, "class Car:")
	end)
end)

describe("Parent navigation in Rust files:", function()
	before_each(function()
		load_fixture("/rust.rs")
	end)

	h.ensure_has_parser("rust")

	it("navigates from method body to impl block", function()
		-- Start inside method body: cursor on calculation
		vim.fn.cursor(21, 30) -- inside "self.radius.powi(2)"
		
		-- First parent: method definition
		tw.goto_parent()
		h.assert_cursor_at(20, 5, "fn area(&self) -> f64 {")
		
		-- Second parent: impl block
		tw.goto_parent()
		h.assert_cursor_at(19, 1, "impl Shape for Circle {")
	end)

	it("navigates from struct field to struct definition", function()
		-- Start inside struct field
		vim.fn.cursor(14, 10) -- inside "radius: f64"
		
		-- Should go to struct definition
		tw.goto_parent()
		h.assert_cursor_at(13, 1, "struct Circle {")
	end)

	it("navigates from nested function to main function", function()
		-- Start inside nested function body
		vim.fn.cursor(73, 30) -- inside println! macro
		
		-- First parent: nested function
		tw.goto_parent()
		h.assert_cursor_at(72, 5, "fn display_area<T: Shape + std::fmt::Display>(shape: &T) {")
		
		-- Second parent: main function
		tw.goto_parent()
		h.assert_cursor_at(57, 1, "fn main() {")
	end)

	it("navigates from if condition to if statement", function()
		-- Start inside if condition
		vim.fn.cursor(64, 8) -- inside "(true)"
		
		-- Should go to if statement
		tw.goto_parent()
		h.assert_cursor_at(64, 5, "if (true) {")
		
		-- Then to main function
		tw.goto_parent()
		h.assert_cursor_at(57, 1, "fn main() {")
	end)

	it("navigates from macro call to containing block", function()
		-- Start inside println! macro
		vim.fn.cursor(46, 20) -- inside "shape_area"
		
		-- Should go to function definition
		tw.goto_parent()
		h.assert_cursor_at(45, 1, "fn print_shape_area(shape: &dyn Shape, blape: &Shape) {")
	end)
end)

describe("Parent navigation in TypeScript files:", function()
	before_each(function()
		load_fixture("/typescript.ts")
	end)

	h.ensure_has_parser("typescript")

	it("navigates from method body to class definition", function()
		-- Start inside method body: cursor on log statement
		vim.fn.cursor(31, 30) -- inside template literal
		
		-- First parent: method definition
		tw.goto_parent()
		h.assert_cursor_at(30, 3, "connect(): void {")
		
		-- Second parent: class definition
		tw.goto_parent()
		h.assert_cursor_at(22, 1, "class Database {")
	end)

	it("navigates from interface property to interface definition", function()
		-- Start inside interface property
		vim.fn.cursor(18, 10) -- inside "host: string"
		
		-- Should go to interface definition
		tw.goto_parent()
		h.assert_cursor_at(17, 1, "interface DatabaseConfig {")
	end)

	it("navigates from decorator to method", function()
		-- Start inside decorator
		vim.fn.cursor(25, 5) -- inside "@logTime"
		
		-- Should go to constructor method
		tw.goto_parent()
		h.assert_cursor_at(26, 3, "constructor(config: DatabaseConfig) {")
	end)

	it("navigates from generic type parameter to class", function()
		-- Start inside generic method
		vim.fn.cursor(54, 20) -- inside "this.data.push(item)"
		
		-- First parent: method definition
		tw.goto_parent()
		h.assert_cursor_at(53, 3, "add(item: T): void {")
		
		-- Second parent: class definition
		tw.goto_parent()
		h.assert_cursor_at(50, 1, "class Container<T> {")
	end)

	it("navigates from async function body to function definition", function()
		-- Start inside async function
		vim.fn.cursor(86, 30) -- inside "calculator.calculateProduct(2, 3)"
		
		-- Should go to async function definition
		tw.goto_parent()
		h.assert_cursor_at(84, 1, "async function main() {")
	end)

	it("navigates from arrow function to Promise", function()
		-- Start inside arrow function
		vim.fn.cursor(98, 40) -- inside "setTimeout(resolve, ms)"
		
		-- Should go to arrow function
		tw.goto_parent()
		h.assert_cursor_at(98, 18, "return new Promise((resolve) => setTimeout(resolve, ms));")
		
		-- Then to function definition
		tw.goto_parent()
		h.assert_cursor_at(97, 1, "function sleep(ms: number): Promise<void> {")
	end)
end)

describe("Parent navigation in C files:", function()
	before_each(function()
		load_fixture("/c.c")
	end)

	h.ensure_has_parser("c")

	it("navigates from function body to function definition", function()
		-- Start inside function body: cursor on malloc call
		vim.fn.cursor(12, 30) -- inside "malloc(sizeof(Account))"
		
		-- Should go to function definition
		tw.goto_parent()
		h.assert_cursor_at(11, 1, "Account* createAccount(int accountNumber, float initialBalance) {")
	end)

	it("navigates from if condition to if statement", function()
		-- Start inside if condition
		vim.fn.cursor(27, 15) -- inside "amount > 0.0f"
		
		-- Should go to if statement
		tw.goto_parent()
		h.assert_cursor_at(27, 5, "if (amount > 0.0f) {")
		
		-- Then to function definition
		tw.goto_parent()
		h.assert_cursor_at(26, 1, "void deposit(Account* account, float amount) {")
	end)

	it("navigates from struct field to struct definition", function()
		-- Start inside struct field
		vim.fn.cursor(6, 10) -- inside "accountNumber"
		
		-- Should go to struct definition
		tw.goto_parent()
		h.assert_cursor_at(5, 1, "typedef struct {")
	end)

	it("navigates from printf call to containing function", function()
		-- Start inside printf call
		vim.fn.cursor(29, 20) -- inside printf format string
		
		-- Should go to function definition
		tw.goto_parent()
		h.assert_cursor_at(26, 1, "void deposit(Account* account, float amount) {")
	end)

	it("navigates from main function body to main", function()
		-- Start inside main function
		vim.fn.cursor(51, 30) -- inside "createAccount(12345, 1000.00f)"
		
		-- Should go to main function
		tw.goto_parent()
		h.assert_cursor_at(50, 1, "int main() {")
	end)

	it("navigates from function call arguments to function call", function()
		-- Start inside function call arguments
		vim.fn.cursor(53, 20) -- inside "500.00f"
		
		-- Should go to function call statement
		tw.goto_parent()
		h.assert_cursor_at(53, 5, "deposit(account, 500.00f);")
		
		-- Then to main function
		tw.goto_parent()
		h.assert_cursor_at(50, 1, "int main() {")
	end)
end)

describe("Parent navigation in Ruby files:", function()
	before_each(function()
		load_fixture("/ruby.rb")
	end)

	h.ensure_has_parser("ruby")

	it("navigates from method body to class definition", function()
		-- Start inside method body: cursor on assignment
		vim.fn.cursor(7, 15) -- inside "@balance = balance"
		
		-- First parent: method definition
		tw.goto_parent()
		h.assert_cursor_at(6, 3, "def initialize(balance = 0, owner = 'Unknown')")
		
		-- Second parent: class definition
		tw.goto_parent()
		h.assert_cursor_at(2, 1, "class BankAccount")
	end)

	it("navigates from if condition to if statement", function()
		-- Start inside if condition
		vim.fn.cursor(13, 10) -- inside "amount > 0"
		
		-- Should go to if statement
		tw.goto_parent()
		h.assert_cursor_at(13, 5, "if amount > 0")
		
		-- Then to method definition
		tw.goto_parent()
		h.assert_cursor_at(12, 3, "def deposit(amount)")
	end)

	it("navigates from instance variable to assignment", function()
		-- Start inside instance variable assignment
		vim.fn.cursor(14, 15) -- inside "@balance += amount"
		
		-- Should go to method definition
		tw.goto_parent()
		h.assert_cursor_at(12, 3, "def deposit(amount)")
		
		-- Then to class definition
		tw.goto_parent()
		h.assert_cursor_at(2, 1, "class BankAccount")
	end)
end)

describe("Parent navigation in HTML files:", function()
	before_each(function()
		load_fixture("/html.html")
	end)

	h.ensure_has_parser("html")

	it("navigates from text content to element", function()
		-- Start inside text content
		vim.fn.cursor(7, 10) -- inside title text
		
		-- Should go to title element
		tw.goto_parent()
		h.assert_cursor_at(7, 5, "<title>Treewalker HTML Test</title>")
	end)

	it("navigates from nested element to parent element", function()
		-- Start inside nested span
		vim.fn.cursor(15, 20) -- inside span content
		
		-- First parent: span element
		tw.goto_parent()
		h.assert_cursor_at(15, 9, "<span>another</span>")
		
		-- Second parent: p element
		tw.goto_parent()
		h.assert_cursor_at(14, 5, "<p>")
	end)

	it("navigates from attribute to element", function()
		-- Start inside attribute value
		vim.fn.cursor(17, 25) -- inside class attribute
		
		-- Should go to element
		tw.goto_parent()
		h.assert_cursor_at(17, 5, '<div class="container">')
	end)
end)
