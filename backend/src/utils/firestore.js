const FIRESTORE_CONNECTION_MESSAGE = 'Firestore belum terkoneksi';

const serializeTimestamp = (value) => {
  if (!value) {
    return null;
  }

  if (typeof value.toDate === 'function') {
    return value.toDate().toISOString();
  }

  if (value instanceof Date) {
    return value.toISOString();
  }

  return value;
};

const sortByCreatedAtDescending = (firstItem, secondItem) => {
  const firstTimestamp = firstItem.created_at
    ? Date.parse(firstItem.created_at)
    : 0;
  const secondTimestamp = secondItem.created_at
    ? Date.parse(secondItem.created_at)
    : 0;

  return secondTimestamp - firstTimestamp;
};

module.exports = {
  FIRESTORE_CONNECTION_MESSAGE,
  serializeTimestamp,
  sortByCreatedAtDescending,
};
