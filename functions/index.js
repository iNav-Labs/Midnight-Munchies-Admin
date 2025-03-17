const functions = require("firebase-functions");
const firestore = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");


admin.initializeApp();

exports.sendOrderNotification = firestore.onDocumentCreated("orders/{orderId}",
    async (event) => {
    //   const orderData = snapshot.data();

      // FCM token from users collection where email = sohamdarji111@gmail.com
      const userRef = admin.firestore().collection("users");
      const userSnapshot = await userRef
          .where("email", "==", "sohamdarji111@gmail.com")
          .limit(1)
          .get();


    // const userSnapshot

      if (userSnapshot.empty) {
        console.log("No user found with the given email.");
        return;
      }

      const userData = userSnapshot.docs[0].data();
      const fcmToken = userData.fcmToken;

      if (!fcmToken) {
        console.log("FCM token not found for the user.");
        return;
      }

      // Create notification message
      const message = {
        token: fcmToken,
        notification: {
          title: "New Order Received!",
        //   body: `Order ${orderData.orderId} has been placed.`,
        body: `Order has been placed.`,
        },
      };

      // Send notification
      try {
        await admin.messaging().send(message);
        console.log("Notification sent successfully!");
      } catch (error) {
        console.error("Error sending notification:", error);
      }
    });
