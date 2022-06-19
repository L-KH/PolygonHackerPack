import Link from 'next/link';
import Image from 'next/image';
import {CgProfile} from 'react-icons/cg';
import logo from '../assets/logowhale.png';
import React from 'react';

const Header = () => {
    const style = {
        wrapper: `bg-[#19041d] w-screen px-[1.2rem] py-[0.8rem] flex `,
        logoContainer: `flex items-center cursor-pointer`,
        logoText: ` ml-[0.8rem] text-white font-semibold text-2xl`,
        searchBar: `flex flex-1 mx-[0.8rem] w-max-[520px] items-center  `,
        searchIcon: `text-[#8a939b] mx-3 font-bold text-lg`,
        searchInput: `h-[2.6rem] w-full border-0 bg-transparent outline-0 ring-0 px-2 pl-0 text-[#e6e8eb] placeholder:text-[#8a939b]`,
        headerItems: ` flex items-center justify-end`,
        headerItem: `text-white px-4 font-bold text-[#c8cacd] hover:text-white cursor-pointer`,
        headerIcon: `text-[#8a939b] text-3xl font-black px-4 hover:text-white cursor-pointer`,
    }
  return (
    <div className={style.wrapper}>
        <Link href='/'>
        <div className={style.logoContainer}>
            <Image src={logo} height={40} width={40}/>
            <div className={style.logoText}>Box Finance</div>
        </div>
        </Link>
        <div className={style.searchBar}></div>
        <div className={style.headerItems}>
            <Link href='/Boxes'>
                <div className={style.headerItem}>BOXES</div>
            </Link>
            <Link href='/Account'>
                <div className={style.headerIcon}>
                    <CgProfile/>
                </div>
            </Link>
        </div>
    </div>
  )
}

export default Header