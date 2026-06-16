class RevisionLogAction {
  const RevisionLogAction._();

  static const create = 'create';
  static const update = 'update';
  static const delete = 'delete';
  static const importData = 'import';
  static const exportData = 'export';
  static const settings = 'settings';
  static const clearLogs = 'clearLogs';

  static const values = <String>{
    create,
    update,
    delete,
    importData,
    exportData,
    settings,
    clearLogs,
  };
}
