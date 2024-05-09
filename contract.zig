const std = @import("std");

/// Response type of contract call.
/// This can be extended to include other details.
fn ContractReturn(T: type) type {
    return struct {
        value: T,
    };
}

/// This type executes the call to the blockchain.
/// It holds the functions to execute blockchain calls
fn ContractFunc(comptime T: type, comptime R: type) type {
    return struct {
        name: [:0]const u8,

        const self = @This();
        pub fn call(s: self, opt: T) !?ContractReturn(R) {
            std.debug.print("function_name={s}\n", .{s.name});
            std.debug.print("function_opt={?}\n", .{opt});

            return switch (R) {
                u128 => ContractReturn(R){ .value = 4 },
                []const u8 => ContractReturn(R){ .value = "string value" },
                else => null,
            };
        }
    };
}

const Token = enum(u8) {
    function = 0,
    event,

    view,
    pure,
    returns,

    string,
    uint,
    uint256,
    address,
    @"address[]",

    indexed,
};

fn tokenMap(t: Token) type {
    return switch (t) {
        Token.uint, Token.uint256 => u128,
        Token.address => []const u8,
        Token.string => []const u8,
        Token.@"address[]" => []const []const u8,
        else => void,
    };
}

/// Return data array with sentinel
fn addZ(comptime len: usize, value: *const [len]u8) [len:0]u8 {
    var terminated_value: [len:0]u8 = undefined;
    terminated_value[len] = 0;
    @memcpy(terminated_value[0..], value[0..len]);
    return terminated_value;
}

/// Create a Contract type from smart contract abi.
/// User needs to call init to get the instance of the contract.
///
/// Example:
///
/// const fns = [_][:0]const u8{
///
///     "function decimals() view returns (string)",
///
///     "function symbol() view returns (string)",
///
///     "function balanceOf(address addr) view returns (uint)",
///
///     "function transfer(address to, uint amount)",
///
///     "event Transfer(address indexed from, address indexed to, uint amount)",
///
/// };
///
/// const c = Contract(&fns).init();
///
/// _ = try c.functions.Transfer.call(.{ .from = "0x0", .to = "0x1", .amount = 3 });
pub fn Contract(
    comptime fns: []const [:0]const u8,
) type {
    var fields: [fns.len]std.builtin.Type.StructField = undefined;
    var field_len = 0;
    @setEvalBranchQuota(2000);
    inline for (fns, 0..) |f, f_index| {
        _ = f_index;
        var tokens = std.mem.splitAny(u8, f, " (),");
        var fname: [:0]const u8 = "";
        var args: [10]std.builtin.Type.StructField = undefined;
        var argLen = 0;
        var retType: ?type = null;
        while (tokens.next()) |token| {
            if (!@hasField(Token, token)) {
                continue;
            }
            const token_field: Token = @field(Token, token);
            switch (token_field) {
                Token.function, Token.event => {
                    const next = tokens.next().?;
                    fname = &addZ(next.len, next[0..]);
                },
                Token.string, Token.address => {
                    var next = tokens.next().?;
                    while (true) {
                        if (std.mem.eql(u8, next, " ") or std.mem.eql(u8, next, "indexed")) {
                            next = tokens.next().?;
                            continue;
                        }
                        if (std.mem.eql(u8, next, "")) {
                            next = tokens.next().?;
                            continue;
                        }
                        break;
                    }

                    const arg_name = &addZ(next.len, next[0..]);
                    if (argLen < 10) {
                        args[argLen] = .{
                            .name = arg_name,
                            .type = []const u8,
                            .default_value = null,
                            .is_comptime = false,
                            .alignment = 0,
                        };
                        argLen += 1;
                    }
                },
                Token.uint, Token.uint256 => {
                    var next = tokens.next().?;
                    while (true) {
                        if (std.mem.eql(u8, next, " ") or std.mem.eql(u8, next, "indexed")) {
                            next = tokens.next().?;
                        }
                        break;
                    }
                    if (std.mem.eql(u8, next, "")) {
                        continue;
                    }
                    const arg_name = &addZ(next.len, next[0..]);

                    if (argLen < 10) {
                        args[argLen] = .{
                            .name = arg_name,
                            .type = u128,
                            .default_value = null,
                            .is_comptime = false,
                            .alignment = 0,
                        };
                        argLen += 1;
                    }
                },
                Token.returns => {
                    var next = tokens.next().?;
                    while (true) {
                        if (!@hasField(Token, next)) {
                            next = tokens.next().?;
                            continue;
                        }
                        break;
                    }

                    const retName: Token = @field(Token, next);
                    retType = tokenMap(retName);
                },
                else => continue,
            }
        }

        const arg_opts = @Type(.{
            .Struct = .{
                .layout = .auto,
                .backing_integer = null,
                .fields = args[0..argLen],
                .decls = &[_]std.builtin.Type.Declaration{},
                .is_tuple = false,
            },
        });

        const func = .{
            .name = fname,
            .type = ContractFunc(arg_opts, retType orelse u1),
            .default_value = null,
            .is_comptime = false,
            .alignment = 0,
        };

        fields[field_len] = func;
        field_len += 1;
    }

    const constructed = @Type(.{
        .Struct = .{
            .layout = .auto,
            .backing_integer = null,
            .fields = fields[0..],
            .decls = &[_]std.builtin.Type.Declaration{},
            .is_tuple = false,
        },
    });

    return struct {
        functions: constructed,
        const Self = @This();

        pub fn init() Self {
            var s: Self = undefined;
            inline for (@typeInfo(constructed).Struct.fields) |field| {
                @field(s.functions, field.name) = field.type{ .name = field.name };
            }
            return s;
        }

        pub fn getA(s: Self) u8 {
            _ = s;
            return 1;
        }
    };
}
