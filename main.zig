const std = @import("std");
const Contract = @import("./contract.zig").Contract;

const Token = enum(u8) {
    function = 0,
    event,

    view,
    pure,
    returns,

    string,
    uint,
    uint256,
    @"address[]",

    indexed,
};

pub fn main() !void {
    const fns = [_][:0]const u8{
        "function decimals() view returns (string)",
        "function symbol() view returns (string)",
        "function balanceOf(address addr) view returns (uint)",
        "function transfer(address to, uint amount)",
        "event Transfer(address indexed from, address indexed to, uint amount)",
    };
    const c = Contract(&fns).init();

    const tr = try c.functions.Transfer.call(.{ .from = "0x0", .to = "0x1", .amount = 3 });
    std.debug.print("contract={?}\n", .{tr});

    const r = try c.functions.balanceOf.call(.{ .addr = "0x0" });
    std.debug.print("contract={?}\n", .{r});

    const s = try c.functions.decimals.call(.{});
    std.debug.print("contract={s}\n", .{s.?.value});

    const sy = try c.functions.symbol.call(.{});
    std.debug.print("contract={s}\n", .{sy.?.value});

    const t = try c.functions.transfer.call(.{ .to = "0x0", .amount = 9 });
    std.debug.print("contract={?}\n", .{t});
}
