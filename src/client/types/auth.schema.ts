/**
 * @module client/types/auth.schema
 * @layer Model (Validation Schemas — Authentication)
 * @purpose Zod v4 schemas for consumer login, 10-second signup, password recovery, and account deletion.
 */

import { z } from "zod";

export const loginSchema = z.object({
	email: z
		.string()
		.trim()
		.min(1, "이메일 주소를 입력해 주세요.")
		.email("올바른 이메일 형식을 확인해 주세요."),
	password: z
		.string()
		.min(1, "비밀번호를 입력해 주세요.")
		.max(200, "비밀번호는 200자 이하로 입력해 주세요."),
});

export type LoginFormValues = z.infer<typeof loginSchema>;

export const signupSchema = z.object({
	name: z.string().trim().max(50, "닉네임은 50자 이하로 입력해 주세요."),
	email: z
		.string()
		.trim()
		.min(1, "이메일 주소를 입력해 주세요.")
		.email("올바른 이메일 형식을 확인해 주세요."),
	password: z
		.string()
		.min(10, "안전한 보호를 위해 비밀번호는 10자 이상 입력해 주세요.")
		.max(200, "비밀번호는 200자 이하로 입력해 주세요."),
});

export type SignupFormValues = z.infer<typeof signupSchema>;

export const forgotPasswordSchema = z.object({
	email: z
		.string()
		.trim()
		.min(1, "가입한 이메일 주소를 입력해 주세요.")
		.email("올바른 이메일 형식을 확인해 주세요."),
});

export type ForgotPasswordFormValues = z.infer<typeof forgotPasswordSchema>;

export const resetPasswordSchema = z.object({
	password: z
		.string()
		.min(10, "새 비밀번호는 10자 이상 200자 이하로 입력해 주세요.")
		.max(200, "비밀번호는 200자 이하로 입력해 주세요."),
});

export type ResetPasswordFormValues = z.infer<typeof resetPasswordSchema>;

export const deleteAccountSchema = z.object({
	password: z.string().min(1, "본인 확인을 위해 비밀번호를 입력해 주세요."),
});

export type DeleteAccountFormValues = z.infer<typeof deleteAccountSchema>;
