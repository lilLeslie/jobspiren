'use client';

import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { signUp, SignUpState } from './actions'
import { useActionState } from 'react'

const initialState: SignUpState = {
    error: null,
};

export default function SignUpPage() {
    const [state, formAction, isPending] = useActionState(signUp, initialState);

    return (
        <div className="flex flex-col min-h-[80vh] items-center justify-center p-4">
            <Card className="w-full max-w-md">
                <CardHeader>
                    <CardTitle className='text-xl'>Opret en bruger</CardTitle>
                </CardHeader>
                <form action={formAction}>
                    <CardContent className='space-y-4'>
                        {state?.error && !state.fieldErrors && (
                            <div className="rounded-md">
                                {state.error}
                            </div>
                        )}
                        <div className="grid gap-2">
                            <Label htmlFor='email'>Email</Label>
                            <Input
                                id="email"
                                name='email'
                                type="email"
                                placeholder="email"
                                required
                            />
                            {state?.fieldErrors?.email && (
                                <p className='text-xs'>
                                    {state.fieldErrors.email[0]}
                                </p>
                            )}
                        </div>
                        <div className="grid gap-2">
                            <Label>Adgangskode</Label>
                            <Input
                                id='password'
                                name='password'
                                type='password'
                                placeholder='adgangskode'
                                required
                            />
                            {state?.fieldErrors?.password && (
                                <p className='text-xs'>
                                    {state.fieldErrors.password[0]}
                                </p>
                            )}
                        </div>
                        <div className="grid gap-2">
                            <Label>Gentag adgangskode</Label>
                            <Input
                                id='confirm-password'
                                name='confirm-password'
                                type='password'
                                placeholder='gentag adgangskode'
                                required
                            />
                            {state?.fieldErrors?.confirmPassword && (
                                <p className="text-xs">
                                    {state.fieldErrors.confirmPassword[0]}
                                </p>
                            )}
                        </div>
                        <Button variant="outline" type="submit" className="w-full" disabled={isPending}>
                            {isPending ? 'Opretter bruger...' : 'Opret bruger'}
                        </Button>
                    </CardContent>
                </form>
            </Card>
        </div>
    )
}
