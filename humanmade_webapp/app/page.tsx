import InputForm from "@/components/InputForm";
import Image from "next/image";
import Navbar from "@/components/Navbar";

export default function Home() {
  return (
    <div className="flex flex-row items-center justify-center sm:justify-between h-full w-full max-w-[1500px]">
      
      <InputForm/>

      <div className="w-full  justify-center sm:flex hidden">
        <h1 className="font-sans font-extrabold text-[90px] text-[#508B0D] ">Verify the reality<br/>In front of your<br/>Eyes.</h1>
      </div>

      <Navbar />
    </div>
  );
}