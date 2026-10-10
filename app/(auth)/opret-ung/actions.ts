'use server';

import { signUpSchema } from "@/lib/validations/auth";
import { createClient } from "@/lib/supabase/server";
import { redirect } from 'next/navigation'

export type SignUpState = {
    error?: string | null;
    fieldErrors?: {
        email?: string[],
        password?: string[],
        confirmPassword?: string[]
    }
};

export async function signUp(
    prevState: SignUpState,
    formData: FormData
): Promise<SignUpState> {

    const rawData = {
        email: formData.get('email'),
        password: formData.get('password'),
        confirmPassword: formData.get('confirm-password')
    };

    const validatedFields = signUpSchema.safeParse(rawData);

    if (!validatedFields.success) {
        const fieldErrors: SignUpState['fieldErrors'] = {};

        for (const issue of validatedFields.error.issues) {
            const field = issue.path[0] as keyof NonNullable<SignUpState['fieldErrors']>;
            if (field) {
                fieldErrors[field] = fieldErrors[field] || []
                fieldErrors[field]!.push(issue.message);
            }
        }

        return {
            error: "Missing fields. Failed to register",
            fieldErrors
        }
    };

    const { email, password } = validatedFields.data;
    const role = "youth" as 'youth' | 'company';

    const supabase = await createClient();

    const { error } = await supabase.auth.signUp({
        email,
        password,
        options: {
            data: {
                role
            },
            // emailRedirectTo: `${process.env.NEXT_PUBLIC_SITE_URL}/auth/callback`,
        },
    });

    if (error) {
        return { error: error.message };
    }
}