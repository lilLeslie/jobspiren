import { NextRequest, NextResponse } from "next/server";

export function proxy(req: NextRequest){
    const basicAuth = req.headers.get('authorization');
    const user = process.env.SITE_USER;
    const pass = process.env.SITE_PASSWORD;

    if (process.env.NODE_ENV === 'development'){
        return NextResponse.next();
    }

    if (user && pass){
        if (basicAuth){
            const authValue = basicAuth.split(' ')[1];
            const [u, p] = atob(authValue).split(':');

            if (u === user && p === pass){
                return NextResponse.next();
            }
        }

        return new NextResponse('Adgang kræver login', {
            status: 401,
            headers: {
                'WWW-Authenticate': 'Basic realm="Jobspiren preview"',
            },
        });

    }
    return NextResponse.next();
}

export const config = {
    matches: ['/((?!_next/static|_next/image|favicon.ico).*)'],
};