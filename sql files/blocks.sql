-- Block Dimension
SHOW PARAMETER db_block_size;

-- Number of blocks for each I/O full scan
SHOW PARAMETER db_file_multiblock_read_count;

-- Tables statics
SELECT table_name, num_rows, blocks, avg_row_len
FROM user_all_tables
WHERE table_name IN ('TOOLS', 'EMPLOYEES', 'EMP_USAGES_NT_TAB', 'ANIMALS', 'BARNS');

