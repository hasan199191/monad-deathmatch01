import { useState } from 'react';
import { signIn, useSession } from 'next-auth/react';
import { useAccount } from 'wagmi';
import { FaTwitter } from 'react-icons/fa';
import { toast } from 'react-hot-toast';

export default function TwitterConnect() {
  const { data: session } = useSession();
  const { address } = useAccount();
  const [isLoading, setIsLoading] = useState(false);

  const connectTwitter = async () => {
    if (!address) {
      toast.error('Please connect your wallet first');
      return;
    }

    try {
      setIsLoading(true);
      
      if (session?.user?.name) {
        const response = await fetch('/api/user/connect-twitter', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            walletAddress: address,
            twitterUsername: session.user.name,
            profileImageUrl: session.user.image
          })
        });

        if (!response.ok) {
          throw new Error('Failed to save wallet address');
        }

        toast.success('Successfully connected wallet with Twitter');
      } else {
        await signIn('twitter');
      }
    } catch (error) {
      console.error('Connection error:', error);
      toast.error('Failed to connect Twitter');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <button
      onClick={connectTwitter}
      disabled={isLoading || !address}
      className={`
        flex items-center justify-center gap-2 
        px-4 py-2 rounded-lg 
        ${session ? 'bg-green-500 hover:bg-green-600' : 'bg-blue-400 hover:bg-blue-500'} 
        ${(!address || isLoading) ? 'opacity-50 cursor-not-allowed' : ''}
        text-white transition-all duration-200
      `}
    >
      <FaTwitter className="w-5 h-5" />
      {session ? 'Connected' : 'Connect X'}
      {isLoading && (
        <svg className="animate-spin h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
          <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
          <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
        </svg>
      )}
    </button>
  );
}