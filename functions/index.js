const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// Function to calculate distance between two coordinates using Haversine formula
function calculateDistance(lat1, lon1, lat2, lon2) {
    const R = 6371; // Radius of the earth in km
    const dLat = deg2rad(lat2 - lat1);
    const dLon = deg2rad(lon2 - lon1);
    const a =
        Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(deg2rad(lat1)) * Math.cos(deg2rad(lat2)) *
        Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    const distance = R * c; // Distance in km
    return distance;
}

function deg2rad(deg) {
    return deg * (Math.PI / 180);
}

// Convert "lat,lng" string to {lat: number, lng: number} object
function parseLocation(locationString) {
    const [lat, lng] = locationString.split(',').map(Number);
    return { lat, lng };
}

const compatibleBloodGroups = {
    'A+': ['A+', 'A-', 'O+', 'O-'],
    'A-': ['A-', 'O-'],
    'B+': ['B+', 'B-', 'O+', 'O-'],
    'B-': ['B-', 'O-'],
    'AB+': ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
    'AB-': ['A-', 'B-', 'AB-', 'O-'],
    'O+': ['O+', 'O-'],
    'O-': ['O-']
};

exports.request = functions.https.onCall({
    region: "asia-south1",
}, async (data, context) => {
    try {
        let userId = context.auth?.uid;

        if (!userId && data.userId) {
            userId = data.userId;
        }

        if (!userId) {
            functions.logger.warn("No authenticated user found. Using request data without user association.");
        }

        const {
            name,
            bloodGroup,
            units,
            date,
            time,
            gender,
            hospital,
            location,
            phone
        } = data.data;

        if (!bloodGroup || !location || !hospital) {
            let missingFields = [];
            if (!bloodGroup) missingFields.push("bloodGroup");
            if (!location) missingFields.push("location");
            if (!hospital) missingFields.push("hospital");

            throw new functions.https.HttpsError(
                'invalid-argument',
                `Missing required fields: ${missingFields.join(", ")}`
            );
        }

        const locationString = await getCoordinatesFromAddress(location);

        const requestLocation = parseLocation(locationString);

        // Maximum distance in kilometers for nearby users
        const MAX_DISTANCE = 50;

        // Get compatible blood types that can donate to the requested blood group
        const compatibleDonors = compatibleBloodGroups[bloodGroup] || [];

        // Query users collection for potential donors
        const usersSnapshot = await admin.firestore()
            .collection('users')
            .where('isDonor', '==', true)
            .get();

        // Filter users based on blood compatibility and distance
        const nearbyUsers = [];

        usersSnapshot.forEach(doc => {
            const userData = doc.data();

            // Skip users without FCM token
            if (!userData.fcmToken) return;

            if (!compatibleDonors.includes(userData.bloodType)) return;

            functions.logger.info(`elegible user: ${JSON.stringify(userData)}`);
            if (!userData.location) return;
            const userLocation = parseLocation(userData.location);

            const distance = calculateDistance(
                requestLocation.lat,
                requestLocation.lng,
                userLocation.lat,
                userLocation.lng
            );

            console.log("Distance: ", distance);

            if (distance <= MAX_DISTANCE) {
                nearbyUsers.push({
                    fcmToken: userData.fcmToken,
                    userId: doc.id,
                    distance: distance.toFixed(1)
                });
            }
        });

        // Store the blood request in Firestore
        const requestRef = await admin.firestore().collection('bloodRequests').add({
            name,
            bloodGroup,
            units,
            date,
            time,
            gender,
            hospital,
            location: locationString,
            phone,
            requestedBy: userId || 'anonymous',
            // createdAt: admin.firestore.FieldValue.serverTimestamp(),
            status: 'active'
        });

        const requestId = requestRef.id;

        // // Prepare notification payload
        // const notificationPayload = {
        //     notification: {
        //         title: `Urgent: ${bloodGroup} Blood Required`,
        //         body: `${units} units needed at ${hospital}. Please help if you can!`
        //     },
        // data: {
        //     requestId,
        //         bloodGroup,
        //         hospital,
        //         click_action: 'FLUTTER_NOTIFICATION_CLICK',
        //             screen: 'bloodRequest'
        // }
        // };



        // Send notifications to nearby users
        const notificationPromises = nearbyUsers.map(user => {
            const message = {
                notification: {
                    title: `${bloodGroup} Blood Required`,
                    body: `${units} units needed at ${hospital}`
                },
                data: {
                    requestId,
                    bloodGroup,
                    hospital,
                    click_action: 'FLUTTER_NOTIFICATION_CLICK',
                    screen: 'bloodRequest',
                    actions: JSON.stringify([
                        {
                            action: 'accept',
                            title: 'Accept'
                        },
                        {
                            action: 'reject',
                            title: 'Reject'
                        }
                    ])
                },
                android: {
                    notification: {
                        click_action: 'FLUTTER_NOTIFICATION_CLICK',
                        default_sound: true,
                        default_vibrate_timings: true,
                        notification_count: 0,
                        visibility: 'PUBLIC'
                    }
                },
                token: user.fcmToken
            };

            functions.logger.info(`Sending notification to user ${user.userId} at ${user.distance}km distance`);
            return admin.messaging().send(message);
        });

        // Wait for all notifications to be sent
        await Promise.all(notificationPromises);

        return {
            success: true,
            notificationsSent: nearbyUsers.length,
            requestId
        };
    } catch (error) {
        functions.logger.error('Error sending notifications:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});

// Helper function to get coordinates from an address if needed
async function getCoordinatesFromAddress(address) {
    try {
        if (/^-?\d+(\.\d+)?,-?\d+(\.\d+)?$/.test(address)) {
            return address;
        }

        // Import the fetch package
        const fetch = require('node-fetch');

        // Encode the address for URL
        const encodedAddress = encodeURIComponent(address);

        // Make request to OSM Nominatim API
        // Add a custom User-Agent as required by Nominatim Usage Policy
        const response = await fetch(
            `https://nominatim.openstreetmap.org/search?q=${encodedAddress}&format=json&limit=1`,
            {
                headers: {
                    'User-Agent': 'RhinoRaktDoors/1.0'
                }
            }
        );

        if (!response.ok) {
            throw new Error(`Geocoding API error: ${response.statusText}`);
        }

        const data = await response.json();

        // Check if the API returned valid results
        if (!data || data.length === 0) {
            throw new Error('No results found for this address');
        }

        // Extract coordinates from the first result
        const lat = data[0].lat;
        const lon = data[0].lon;

        // Return in the format "lat,lng"
        return `${lat},${lon}`;
    } catch (error) {
        functions.logger.error('Error in getCoordinatesFromAddress:', error);
        return null;
    }
}