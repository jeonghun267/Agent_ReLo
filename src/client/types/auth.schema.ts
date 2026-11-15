/**
 * @module client/types/auth.schema
 * @layer Model (Validation Schemas — Authentication)
 * @purpose Zod v4 schemas for consumer login, signup, password recovery, and account deletion.
 *          Each rule names its message by key; the screen shows the sentence for that key in
 *          the reader's language (auth.fieldErrors / shared.fieldErrors, through fieldError()).
 */

import { z } from "zod";

const email = z.string().trim().min(1, "emailRequired").email("emailInvalid");

export const loginSchema = z.object({
	email,
	password: z
		.string()
		.min(1, "loginPasswordRequired")
		.max(200, "passwordTooLong"),
});

export type LoginFormValues = z.infer<typeof loginSchema>;

export const signupSchema = z.object({
	name: z.string().trim().max(50, "nameTooLong"),
	email,
	password: z.string().min(10, "passwordTooShort").max(200, "passwordTooLong"),
});

export type SignupFormValues = z.infer<typeof signupSchema>;

export const forgotPasswordSchema = z.object({ email });

export type ForgotPasswordFormValues = z.infer<typeof forgotPasswordSchema>;

export const resetPasswordSchema = z.object({
	password: z.string().min(10, "passwordTooShort").max(200, "passwordTooLong"),
});

export type ResetPasswordFormValues = z.infer<typeof resetPasswordSchema>;

export const deleteAccountSchema = z.object({
	password: z.string().min(1, "passwordRequired"),
});

export type DeleteAccountFormValues = z.infer<typeof deleteAccountSchema>;
