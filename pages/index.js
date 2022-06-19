import Head from 'next/head'
import Header from '../components/Header'
import Hero from '../components/Hero'
import { useWeb3, useSwitchNetwork  } from '@3rdweb/hooks'
import { useEffect } from 'react'
import toast, { Toaster } from 'react-hot-toast'

const style = {
  wrapper: ``,
  walletConnectWrapper: `flex flex-col justify-center items-center h-screen w-screen bg-[#3b3d42] `,
  button: `border border-[#8fa1b8] bg-[#2081e2] p-[0.8rem] text-xl font-semibold rounded-lg cursor-pointer text-black`,
  switshbutton: `border border-[#8fa1b8] bg-[#3e647a] p-[0.7rem] text-xl font-semibold rounded-lg cursor-pointer text-black`,
  details: `text-lg text-center text=[#8fa1b8] font-semibold mt-4`,
}

export default function Home() {
  const supportChainIds = [80001];
  const { address, chainId, connectWallet, disconnectWallet, getNetworkMetadata } = useWeb3();
  const { switchNetwork } = useSwitchNetwork();

  useEffect(() => {
    
  }, [])

  return (
    <div className={style.wrapper}>
      <Toaster position="top-center" reverseOrder={false} />
      {address ? (
        <>
          <Header />
          <Hero />
        </>
      ) : (
        <div className={style.walletConnectWrapper}>
          <button
            className={style.button}
            onClick={() => connectWallet('injected')}
          >
            Connect Wallet
          </button>
          <div className={style.details}>
            Or <br/>
            switch to Mombai testnet 
          </div>
          <div className={style.details}>
            {supportChainIds.map((cId) => (
            <button className={style.switshbutton} onClick={() => switchNetwork(cId)}>
              {getNetworkMetadata(cId).chainName}
            </button>
          ))}
          </div>
        </div>
      )}
    </div>
  )
}