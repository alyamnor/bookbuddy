const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.deleteUserAccount = functions.https.onCall(async (data, context) => {
  if (!context.auth?.token?.admin) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Only admins can delete users."
    );
  }

  const uid = data.uid;

  try {
    await admin.auth().deleteUser(uid);
    return { success: true };
  } catch (error) {
    console.error("Error deleting user:", error);
    throw new functions.https.HttpsError("internal", error.message);
  }
});
