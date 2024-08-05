const std = @import("std");

const DbInfo = struct {
    page_size: u16,
    table_count: u16,
    fn read(file: std.fs.File) !DbInfo {
        var buf: [2]u8 = undefined;
        _ = try file.seekTo(16);
        _ = try file.read(&buf);
        const page_size = std.mem.readInt(u16, &buf, .big);

        var page_type_buf: [1]u8 = undefined;
        _ = try file.seekTo(100);
        _ = try file.read(&page_type_buf);
        std.debug.assert(page_type_buf[0] == 0x0D);
        var table_buf: [2]u8 = undefined;
        _ = try file.seekBy(2);
        _ = try file.read(&table_buf);
        const table_count = std.mem.readInt(u16, &table_buf, .big);

        return DbInfo{ .page_size = page_size, .table_count = table_count };
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 3) {
        try std.io.getStdErr().writer().print("Usage: {s} <database_file_path> <command>\n", .{args[0]});
        return;
    }

    const database_file_path: []const u8 = args[1];
    const command: []const u8 = args[2];

    if (std.mem.eql(u8, command, ".dbinfo")) {
        var file = try std.fs.cwd().openFile(database_file_path, .{});
        defer file.close();

        const info = try DbInfo.read(file);

        try std.io.getStdOut().writer().print("database page size: {}\n", .{info.page_size});
        try std.io.getStdOut().writer().print("number of tables: {}\n", .{info.table_count});
    }
}
