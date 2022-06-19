import React, { useEffect, useState, useMemo } from 'react'
import Header from '../components/Header';
import { CgWebsite } from 'react-icons/cg';
import Image from 'next/image';
import { AiOutlineInstagram, AiOutlineTwitter } from 'react-icons/ai';
import { HiDotsVertical } from 'react-icons/hi';
import { ethers } from 'ethers';
import stakingcontarct from './abis/stakingbox.json'
import BoxCard from '../components/BoxCard';
const contractaddress = '0x12a071cEB3b340339d49de5140e7cc6AB7887ADa'
import toast, { Toaster } from 'react-hot-toast'
// 
const style = {
  wrapper: ` bg-gradient-to-r from-cyan-500 to-blue-500 justify-center`,
  button: `mx-10  relative text-lg font-semibold px-12 py-4 bg-[#363840] rounded-lg mr-5 text-[#e4e8ea] hover:bg-[#4c505c] cursor-pointer`,

}
const Boxes = () => {
  const [boxesList, setBoxList] = useState([]);
  const [winnerlist, setwinnerlist] = useState([])
  const [signer, setSigner] = useState();
  const [BoxId, setBoxId] = useState();
  useEffect(() => {
    if (signer) return
    getAllBoxes()
  }, [signer])

  const confirmClaim = (msg) => toast(msg)
  async function getAllBoxes() {
    const provider = new ethers.providers.Web3Provider(window.ethereum)
    const signer = provider.getSigner()
    setSigner(signer)
    const stakingbox = new ethers.Contract(
      contractaddress,
      stakingcontarct,
      signer
    )
    let boxId = await stakingbox.BoxId.call();
    setBoxId(boxId.toString())
    const box = [];
    const winnerlist = [];
    for (let i = 0; i <= boxId; i++) {
      let boxes = await stakingbox.get(i.toString());
      let wlist = await stakingbox.getWlist(i.toString())
      winnerlist.push(wlist)
      box.push(boxes);
    }
    setwinnerlist(winnerlist)
    setBoxList(box)
  }
  
  async function deposit() {
    const provider = new ethers.providers.Web3Provider(window.ethereum)
    const signer = provider.getSigner()
    const stakingbox = new ethers.Contract(
      contractaddress,
      stakingcontarct,
      signer
    )
    try {
      const transaction = await stakingbox.deposit()
      await transaction.wait()
      console.log(transaction)
      confirmClaim('transaction successful!')
    } catch (error) {
      console.log({error})
      confirmClaim(error.error.data.message)
    }
    getAllBoxes()
  }
  return (
    <div className={style.wrapper}>
      <Header />
      <div className=" flex mx-auto px-4 py-10">
      {
          boxesList.map((box, Id) =>
          (
            <div className=" mx-auto text-xl justify-center border-solid border-2 border-sky-800 border border-[#151b22] rounded-xl mb-4" key={Id}>
            <BoxCard
              boxnumber={Id}
              box={box}
              winnerlist ={winnerlist[Id].winner}
              
            />
            {winnerlist[Id].winner.length <6 ? (
              <div className="mx-auto py-4">
              <button className={style.button}  onClick={() => deposit()}>
                  Join Box
              </button>
              </div>
              
            ) : (
              <div className="mx-4 px-10 text-xl "> the Box is closed</div>
            )}
            
            </div>
          ))
        }
          <Toaster
            toastOptions={{
              className: '',
              style: {
                border: '1px solid #713200',
                padding: '16px',
                color: '#713200',
              },
            }}
          />
      </div>
    </div>
  )
}

export default Boxes
