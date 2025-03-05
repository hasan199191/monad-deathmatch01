const LoadingSkeleton = () => {
    return (
      <div className="animate-pulse">
        <div className="h-12 bg-[#2A2A2A] rounded-lg mb-4"></div>
        <div className="space-y-3">
          <div className="h-8 bg-[#2A2A2A] rounded-lg w-3/4"></div>
          <div className="h-8 bg-[#2A2A2A] rounded-lg"></div>
          <div className="h-8 bg-[#2A2A2A] rounded-lg w-5/6"></div>
        </div>
      </div>
    );
  };
  
  export default LoadingSkeleton;