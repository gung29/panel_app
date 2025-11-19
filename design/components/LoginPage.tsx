import { useState } from 'react';
import { Lock, User } from 'lucide-react';

interface LoginPageProps {
  onLogin: (username: string) => void;
}

export function LoginPage({ onLogin }: LoginPageProps) {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (username.trim()) {
      onLogin(username);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center p-4 bg-gradient-to-br from-zinc-950 via-black to-zinc-950">
      <div className="w-full max-w-md">
        {/* Logo/Title */}
        <div className="text-center mb-10">
          <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-white/5 backdrop-blur-sm mb-6 border border-white/10">
            <div className="w-8 h-8 rounded-lg bg-white" />
          </div>
          <h1 className="text-white mb-2">Welcome Back</h1>
          <p className="text-zinc-500">Sign in to continue</p>
        </div>

        {/* Login Form */}
        <div className="bg-white/5 backdrop-blur-xl rounded-2xl p-8 border border-white/10">
          <form onSubmit={handleSubmit} className="space-y-5">
            {/* Username Input */}
            <div className="space-y-2">
              <label className="text-zinc-400 text-sm">Username</label>
              <div className="relative">
                <User className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-zinc-600" />
                <input
                  type="text"
                  value={username}
                  onChange={(e) => setUsername(e.target.value)}
                  className="w-full bg-white/5 border border-white/10 rounded-xl pl-12 pr-4 py-3 text-white placeholder-zinc-600 focus:outline-none focus:border-white/30 transition-colors"
                  placeholder="Enter your username"
                  required
                />
              </div>
            </div>

            {/* Password Input */}
            <div className="space-y-2">
              <label className="text-zinc-400 text-sm">Password</label>
              <div className="relative">
                <Lock className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-zinc-600" />
                <input
                  type="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="w-full bg-white/5 border border-white/10 rounded-xl pl-12 pr-4 py-3 text-white placeholder-zinc-600 focus:outline-none focus:border-white/30 transition-colors"
                  placeholder="Enter your password"
                  required
                />
              </div>
            </div>

            {/* Remember Me & Forgot Password */}
            <div className="flex items-center justify-between text-sm pt-2">
              <label className="flex items-center space-x-2 cursor-pointer">
                <input
                  type="checkbox"
                  className="w-4 h-4 rounded border-white/20 bg-white/5 text-white focus:ring-white/50 focus:ring-offset-0"
                />
                <span className="text-zinc-500">Remember me</span>
              </label>
              <button type="button" className="text-white hover:text-zinc-300 transition-colors">
                Forgot password?
              </button>
            </div>

            {/* Login Button */}
            <button
              type="submit"
              className="w-full bg-white hover:bg-zinc-100 text-black rounded-xl py-3 transition-colors mt-6"
            >
              Sign In
            </button>
          </form>

          {/* Divider */}
          <div className="relative my-6">
            <div className="absolute inset-0 flex items-center">
              <div className="w-full border-t border-white/10" />
            </div>
            <div className="relative flex justify-center text-sm">
              <span className="px-4 bg-white/5 text-zinc-600">or continue with</span>
            </div>
          </div>

          {/* Social Login */}
          <div className="grid grid-cols-3 gap-3">
            {['Google', 'Discord', 'Steam'].map((provider) => (
              <button
                key={provider}
                type="button"
                className="px-4 py-2.5 bg-white/5 border border-white/10 rounded-xl text-zinc-500 hover:bg-white/10 hover:text-zinc-300 transition-all text-sm"
              >
                {provider}
              </button>
            ))}
          </div>
        </div>

        {/* Sign Up Link */}
        <p className="text-center mt-6 text-zinc-500">
          Don't have an account?{' '}
          <button className="text-white hover:text-zinc-300 transition-colors">
            Sign up
          </button>
        </p>
      </div>
    </div>
  );
}
