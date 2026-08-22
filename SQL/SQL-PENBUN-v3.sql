>> Rename [id_status] to [is_active] on [tb_customer_type]...
   ? Executed: EXEC sp_rename 'tb_customer_type.id_status', 'is_active', 'COLUMN'

>> Rename [id_status] to [is_active] on [tb_reference]...
   ? Executed: EXEC sp_rename 'tb_reference.id_status', 'is_active', 'COLUMN'

>> Rename [id_status] to [is_active] on [tb_users]...
   ? Executed: EXEC sp_rename 'tb_users.id_status', 'is_active', 'COLUMN'

Completion time: 2026-06-09T20:17:12.4278135+07:00

>> Cleaning up [base_credit_day] from [tb_customer_type]...
   ? Dropped Constraint: DF__tb_custom__base___64398C7F
   ? Dropped Column: base_credit_day

Completion time: 2026-06-10T12:00:00.0000000+07:00
