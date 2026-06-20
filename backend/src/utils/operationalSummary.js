const getCollectionSnapshot = (db, collectionName) =>
  db.collection(collectionName).get();

const calculateFinanceTotals = (documents) => {
  let totalIncome = 0;
  let totalExpense = 0;

  documents.forEach((document) => {
    const transaction = document.data();
    const amount =
      typeof transaction.amount === 'number' &&
      Number.isFinite(transaction.amount)
        ? transaction.amount
        : 0;

    if (transaction.type === 'income') {
      totalIncome += amount;
    } else if (transaction.type === 'expense') {
      totalExpense += amount;
    }
  });

  return {
    total_income: totalIncome,
    total_expense: totalExpense,
    profit: totalIncome - totalExpense,
  };
};

const getOperationalSummary = async (db, includeActiveModules = false) => {
  const [
    modulesSnapshot,
    logbooksSnapshot,
    inventorySnapshot,
    schedulesSnapshot,
    financeSnapshot,
  ] = await Promise.all([
    getCollectionSnapshot(db, 'farm_modules'),
    getCollectionSnapshot(db, 'logbooks'),
    getCollectionSnapshot(db, 'inventory_items'),
    getCollectionSnapshot(db, 'operational_schedules'),
    getCollectionSnapshot(db, 'finance_transactions'),
  ]);

  const financeTotals = calculateFinanceTotals(financeSnapshot.docs);
  const summary = {
    total_modules: modulesSnapshot.size,
    total_logbooks: logbooksSnapshot.size,
    total_inventory_items: inventorySnapshot.size,
    low_stock_items: inventorySnapshot.docs.filter(
      (document) => document.data().is_low_stock === true,
    ).length,
    total_schedules: schedulesSnapshot.size,
    ...financeTotals,
  };

  if (includeActiveModules) {
    summary.active_modules = modulesSnapshot.docs.filter(
      (document) => document.data().is_active === true,
    ).length;
  }

  return summary;
};

module.exports = { calculateFinanceTotals, getOperationalSummary };
