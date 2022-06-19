import React from 'react';
import Image from 'next/image';
import whale from '../assets/whale.svg';
import logo from '../assets/logowhale.png';
import Link from 'next/link';

const style = {
  wrapper: `relative`,
  container: `before:content-[''] before:bg-red-500 before:absolute before:top-0 before:left-0 before:right-0 before:bottom-0 before:bg-[url('https://cdn.futura-sciences.com/buildsv6/images/wide1920/6/9/7/697bcaaf34_50179672_ocean-min.jpg')] before:bg-cover before:bg-center before:opacity-50 before:blur`,
  contentWrapper: `flex h-screen relative justify-center flex-wrap items-center`,
  imgContainer: `h-2/3 w-full overflow-hidden flex justify-center items-center`,
  nftImg: `w-full object-cover`,
  copyContainer: `w-1/2`,
  title: `relative text-white text-[46px] font-semibold`,
  description: `text-[#203140] container-[400px] text-2xl mt-[0.8rem] mb-[2.5rem]`,
  ctaContainer: `flex`,
  accentedButton: ` relative text-lg font-semibold px-12 py-4 bg-[#2181e2] rounded-lg mr-5 text-white hover:bg-[#42a0ff] cursor-pointer`,
  button: ` relative text-lg font-semibold px-12 py-4 bg-[#363840] rounded-lg mr-5 text-[#e4e8ea] hover:bg-[#4c505c] cursor-pointer`,
  cardContainer: `rounded-[3rem]`,
  infoContainer: `h-20 bg-[#313338] p-4 rounded-b-lg flex items-center text-white`,
  boxes: `flex flex-col justify-center ml-4`,
  name: ``,
  infoIcon: `flex justify-end items-center flex-1 text-[#8a939b] text-3xl font-bold`,
}

const Hero = () => {
  return (
    <div className={style.wrapper}>
      <div className={style.container}>
        <div className={style.contentWrapper}>
          <div className={style.copyContainer}>
          <div className={style.imgContainer}>
            <Image className={style.nftImg} src={whale} alt=''>
            </Image>
          </div>
            <div className={style.title}>
              New Distribution Reward for Staker.
            </div>
            <div className={style.description}>
              Protect your staking investement from whale. <br/>
              Random selection using ChainLink. <br/>
              Limit amount and number of stakers for every StakingBox.<br/>
              Distribution every 30 Day after the close of StakingBox.<br/>
            </div>
            <div className={style.ctaContainer}>
                <Link href={'/Boxes'}>
                <button className={style.accentedButton}>Join</button>
                </Link>
              
            </div>
          </div>
          
        </div>
      </div>
    </div>
  )
}

export default Hero