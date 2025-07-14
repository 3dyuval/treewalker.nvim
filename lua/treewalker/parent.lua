local operations = require("treewalker.operations")
local nodes = require("treewalker.nodes")

local M = {}

-- Node types that are considered trivial parents (single-child wrappers)
local TRIVIAL_PARENT_TYPES = {
	"expression_statement", -- Wrapper for standalone expressions
	"parenthesized_expression", -- Wrapper for parentheses
	"argument_list", -- Function call arguments container
	"parameters", -- Function parameter container
	"parameter_list", -- Function parameter list
	"formal_parameters", -- Java/C style parameters
	"block", -- Simple block wrapper (when it's just a container)
	"statement_block", -- Statement container
	"compound_statement", -- C-style compound statements
	"primary_expression", -- Basic expression wrapper
	"postfix_expression", -- Expression suffix wrapper
	"call_expression", -- When it's just wrapping the actual call
	"member_expression", -- When it's just wrapping member access
	"array", -- Simple array wrapper
	"object", -- Simple object wrapper
	"pair", -- Key-value pair wrapper
	"property", -- Object property wrapper
	"element", -- Array element wrapper
	"string_literal", -- String wrapper
	"number_literal", -- Number wrapper
	"boolean_literal", -- Boolean wrapper
	"identifier", -- Variable name wrapper
	"field", -- Struct/class field wrapper
	"variable", -- Variable wrapper
	"type", -- Type annotation wrapper
	"annotation", -- Generic annotation wrapper
}

-- Node types that represent meaningful semantic boundaries (non-trivial parents)
local NONTRIVIAL_PARENT_TYPES = {
	"function_declaration",
	"function_definition",
	"method_declaration",
	"method_definition",
	"class_declaration",
	"class_definition",
	"interface_declaration",
	"struct_declaration",
	"enum_declaration",
	"module_declaration",
	"namespace_declaration",
	"variable_declaration",
	"const_declaration",
	"let_declaration",
	"assignment_expression",
	"binary_expression",
	"logical_expression",
	"conditional_expression",
	"for_statement",
	"while_statement",
	"if_statement",
	"switch_statement",
	"try_statement",
	"catch_clause",
	"finally_clause",
	"return_statement",
	"throw_statement",
	"import_statement",
	"export_statement",
	"object_expression",
	"array_expression",
	"call_expression", -- When it contains meaningful call logic
	"new_expression",
	"await_expression",
	"yield_expression",
	"arrow_function",
	"function_expression",
	"lambda_expression",
	"closure_expression",
}

---Check if a node represents a trivial parent that should be skipped
---@param node TSNode
---@return boolean
local function is_trivial_parent(node)
	local node_type = node:type()

	-- Check against trivial parent types
	for _, trivial_type in ipairs(TRIVIAL_PARENT_TYPES) do
		if node_type:match(trivial_type) then
			return true
		end
	end

	-- Additional logic: single-child containers are often trivial
	if node:child_count() == 1 then
		local child = node:child(0)
		if child then
			-- Skip if parent and child start at same position (wrapper scenario)
			local parent_row, parent_col = node:range()
			local child_row, child_col = child:range()
			if parent_row == child_row and parent_col == child_col then
				return true
			end
		end
	end

	return false
end

---Check if a node represents a non-trivial parent worth navigating to
---@param node TSNode
---@return boolean
local function is_nontrivial_parent(node)
	local node_type = node:type()

	-- Don't navigate to nodes that aren't valid jump targets
	if not nodes.is_jump_target(node) then
		return false
	end

	-- Skip if it's explicitly trivial
	if is_trivial_parent(node) then
		return false
	end

	-- First check if it's explicitly in our non-trivial list
	for _, nontrivial_type in ipairs(NONTRIVIAL_PARENT_TYPES) do
		if node_type:match(nontrivial_type) then
			return true
		end
	end

	-- For nodes not in either list, apply heuristics:
	-- - Multi-child nodes that span multiple lines are typically structural
	-- - Nodes that are meaningful jump targets
	if node:child_count() > 1 then
		local start_row, _, end_row = node:range()
		if end_row > start_row then
			return true
		end
	end

	-- Single line nodes with multiple children can still be meaningful
	if node:child_count() > 2 then
		return true
	end

	return false
end

---Navigate to the next non-trivial parent of the current node
---@return boolean success True if navigation occurred, false otherwise
function M.goto_nontrivial_parent()
	local cursor = nodes.get_current()
	local parent = cursor:parent()

	while parent do
		-- Skip trivial parents (single-child wrappers)
		if is_nontrivial_parent(parent) then
			local should_add_jumplist = require("treewalker").opts.jumplist
			if should_add_jumplist then
				vim.cmd("normal! m'")
			end

			operations.jump(parent, nodes.get_srow(parent))

			if should_add_jumplist then
				vim.cmd("normal! m'")
			end
			return true
		end
		parent = parent:parent()
	end
	return false
end

return M
