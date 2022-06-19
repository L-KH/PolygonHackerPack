import React, { useEffect, useState, useMemo } from 'react'
import Header from '../components/Header';
import { CgWebsite } from 'react-icons/cg';
import Image from 'next/image';
import { AiOutlineInstagram, AiOutlineTwitter } from 'react-icons/ai';
import { HiDotsVertical } from 'react-icons/hi';
import { ethers } from 'ethers';
import stakingcontarct from './abis/stakingbox.json'
import BoxCard from '../components/BoxCard';
import TokenLogo from '../assets/logowhale.png'
const contractaddress = '0x12a071cEB3b340339d49de5140e7cc6AB7887ADa'
import toast, { Toaster } from 'react-hot-toast';
// 
const style = {
  wrapper: ` bg-gradient-to-r from-cyan-500 to-blue-500 justify-center`,
  Container: ` flex `,
  details: `p-3`,
  info: ` flex justify-between text-[#e4e8eb] drop-shadow-xl`,
  list: ` flexfont-bold text-lg list-decimal`,
  infoRight: `flex-0.4 text-right`,
  button: `border border-[#8fa1b8] bg-[#2081e2] p-[0.8rem] text-xl font-semibold rounded-lg cursor-pointer text-black`,
}
const Account = () => {
  const [account, setSigner] = useState();
  const [boxesList, setBoxList] = useState([]);
  const [Balance, setBalance] = useState()
  const [winnerlist, setwinnerlist] = useState([])
  const [msg, setmsg] = useState()


  useEffect(() => {
    if (account) return
    accountinfo()
  }, [account])

  async function accountinfo() {
    const provider = new ethers.providers.Web3Provider(window.ethereum)
    const signer = provider.getSigner()
    const account = signer.getAddress()
    setSigner(account)
    const stakingbox = new ethers.Contract(
      contractaddress,
      stakingcontarct,
      signer
    )
    let boxId = await stakingbox.BoxId.call()
    let Balance = await stakingbox.balanceOf(account);
    setBalance(ethers.utils.formatUnits(Balance.toString(), 'ether'))
    const box = [];
    const winnerlist = [];
    const histoBox = []
    for (let i = 0; i <= boxId; i++) {
      let boxes = await stakingbox.get(i.toString());
      for(let k = 0; k <= boxes.particip.length; k++){
        if ((await account).toString() == boxes.particip[k]){
          histoBox.push({i, k})
        }
      }
      let wlist = await stakingbox.getWlist(i.toString())
      for(let j = 0; j <= 5; j++){
          if ((await account).toString() == wlist.winner[j]){
            winnerlist.push({'order': j,'box': i})
          }
      }
      box.push(boxes);
    }
    console.log(winnerlist)
    setwinnerlist(winnerlist)
    setBoxList(histoBox)
  }
  async function Claim(id) {
    const provider = new ethers.providers.Web3Provider(window.ethereum)
    const signer = provider.getSigner()
    const stakingbox = new ethers.Contract(
      contractaddress,
      stakingcontarct,
      signer
    )
    try {
      const transaction = await stakingbox.Claim(id)
      await transaction.wait()
      getAllBoxes()
      confirmClaim('Done!')
    } catch (error) {
      console.log(error.error.data.message)
      confirmClaim(error.error.data.message)
    }
    
  }
  const confirmClaim = (msg) => toast(msg)
  return (
    <div className={style.wrapper}>
      <Header />
        <div className={style.info}>
            <div className="mx-auto py-10 px-10 text-xl text-[#0d2021]">Balance {Balance} BXF </div>
        </div>
      <div className={style.Container}>
        <div className="mx-auto px-10 py-10 flex "> 
          <div className={style.list}> My Staking reward </div>
          <div className="h-screen mx-auto px-10 py-10 flex"> 
            {
              winnerlist?.map((winnerlist, id) => (
                <div className={style.details} key={id}>
                <div className='text-black-600 ' > Box Number: {winnerlist.box} , My Order: {winnerlist.order}</div>
                <div className={style.infoRight}>
                  <button  onClick={()=> Claim(winnerlist.box)} className={style.button} >
                    Claim Reward
                  </button>
                  <Toaster />
                </div>
                </div>
              ))
            }
          </div>
        </div>
      </div>
    </div>
  )
}

export default Account