import { getAuth, sendPasswordResetEmail } from 'firebase/auth';

export const forgotPassword = async (req, res) => {
    try {
        const { email } = req.body;
        const auth = getAuth();
        await sendPasswordResetEmail(auth, email);
        res.status(200).json({ success: true, message: 'Password reset email sent successfully' });
    } catch (error) {
        console.error('Error sending password reset email:', error);
        if (error.code === 'auth/user-not-found') {
            return res.status(404).json({ success: false, message: 'No account found with this email address' });
        }
        if (error.code === 'auth/invalid-email') {
            return res.status(400).json({ success: false, message: 'Invalid email address' });
        }
        res.status(500).json({ success: false, message: 'Failed to send password reset email' });
    }
};
