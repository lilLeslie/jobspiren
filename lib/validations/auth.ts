import { z } from "zod";

export const signUpSchema = z.object({
    email: z.email({message: 'Indtast venligst en gyldt e-mailadresse'}),
    password: z.string().min(8, {message: 'Adgangskoden skal være på mindst 8 tegn.'})
    .regex(/[A-Z]/, {message: 'Adgangskoden skal indeholde mindst ét stort bogstav.'})
    .regex(/[a-z]/, {message: 'Adgangskoden skal indeholde mindst ét lille bogstav.'})
    .regex(/[0-9]/, {message: 'Adgangskode skal indeholde mindst ét tal.'}),
    confirmPassword: z.string(),
}).refine((data) => data.password === data.confirmPassword, {
    message: "Adgangskoderne matcher ikke",
    path: ["confirmPassword"]
});

export type SignUpInput = z.output<typeof signUpSchema>;